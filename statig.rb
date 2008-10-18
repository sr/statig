%w(rubygems
thor
yaml
haml/engine
maruku/string_utils).each { |lib| require lib }

class SerializableProc
  def initialize(block)
    @block = block
    to_proc
  end

  def to_proc
    eval "Proc.new{ #{@block} }"
  end

  def method_missing(*args)
    to_proc.send(*args)
  end
end

class Statig < Thor
  include MaRuKu::Strings

  def self.default_options
    { :extensions => [:text, :textile],
      :text       => SerializableProc.new('|content| require "bluecloth"; BlueCloth.new(content).to_html'),
      :textile    => SerializableProc.new('|content| require "redcloth"; RedCloth.new(content).to_html'),
      :deepth     => 2,
      :template   => 'template.haml'
    }
  end

  desc 'build', 'Build website in DIRECTORY'
  method_options :force => :boolean
  def build(directory=Dir.pwd)
    directory = File.expand_path(directory)
    Dir.chdir(directory) do
      abort('needs to be run inside of a git working directory') unless git?
      files_list.each do |source|
        destination = source.sub(File.extname(source), '.html')
        next if !need_update?(source, destination) && !options[:force]
        puts "#{source} -> #{destination}"
        File.open(destination, 'w') do |file|
          file << content_for(source, destination)
          git_ignore_if_needed(file.path)
        end
      end
    end
  end

  private
    def content_for(source, destination)
      source_content = File.read(source)
      meta_data = parse_email_headers(source_content)
      formatted = formatter_for(source).call(meta_data[:data])
      return formatted unless template
      engine = Haml::Engine.new(template, :format => :html4)
      engine.render(Object.new, meta_data.update(:data => formatted))
    end

    def formatter_for(file_name)
      opts[File.extname(file_name)[1..-1].to_sym]
    end

    def need_update?(source, destination)
      !File.exists?(destination) || File.mtime(source) > File.mtime(destination)
    end

    def files_list
      @files ||= Dir[glob].reject { |file| file =~ excludes }
    end

    def glob
      @glob ||= "#{'**/' * opts[:deepth]}*.{#{opts[:extensions].map(&:to_s).join(',')}}"
    end

    def excludes
      @excludes ||= Regexp.union(*(opts[:excludes] || []))
    end

    def template
      @template ||= File.exists?(opts[:template]) ? File.read(opts[:template]) : nil
    end

    def opts
      @opts ||= Statig.default_options.update((YAML.load_file('.statig.yml') rescue {}))
    end

    def git_ignore_if_needed(file)
      unless git_ignored?(file)
        puts "Ignoring #{file}"
        File.open('.gitignore', 'a') { |f| f << "#{file}\n" }
      end
    end

    def git_ignored?(file)
      return false unless File.exists?('.gitignore')
      File.readlines('.gitignore').map(&:chomp).include?(file)
    end

    def git?
      `git status &> /dev/null`
      $?.exitstatus.to_i == 1
    end
end
