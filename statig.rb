%w(rubygems
thor
yaml).each { |lib| require lib }

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
  desc 'build', 'Build website in DIRECTORY'
  method_options :force => :boolean, :config => :optional
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
      parsed = parse_email_headers(File.read(source))

      if template?
        template(parsed)
      else
        formatter_for(source).call(parsed[:content])
      end
    end

    def formatter_for(file_name)
      config[File.extname(file_name)[1..-1].to_sym]
    end

    def need_update?(source, destination)
      !File.exists?(destination) || File.mtime(source) > File.mtime(destination)
    end

    def files_list
      @files ||= Dir[glob].reject { |file| file =~ excludes }
    end

    def glob
      @glob ||= "#{'**/' * config[:deepth]}*.{#{config[:extensions].map(&:to_s).join(',')}}"
    end

    def excludes
      @excludes ||= Regexp.union(*(config[:excludes] || []))
    end

    def template(variables)
      formatter_for(config[:template]).call(load_template_file, variables)
    end

    def template?
      load_template_file
    end

    def load_template_file
      @template_content ||= File.exists?(config[:template]) ? File.read(config[:template]) : nil
    end

    def config
      @config = begin
        YAML.load_file(options[:config] || 'statig.yml')
      rescue Errno::ENOENT
        {}
      end
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

    def parse_email_headers(string)
      parsed = {:headers => [], :content => string}
      return parsed unless string =~ /((\w[\w\s]+: .*\n)+)\n/

      parsed.update(:content => $')

      headers = $1.split("\n").inject({}) do |headers, line|
        parts = line.split(':', 2)
        key   = parts.first.strip.downcase.to_sym
        value = parts.last.strip
        headers.update(key => value)
      end

      parsed.update(:headers => headers)
    end
end
