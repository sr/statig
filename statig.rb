require 'yaml'

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
        next if !needs_update?(source, destination) && !options[:force]
        puts "#{source} -> #{destination}"
        File.open(destination, 'w') do |file|
          file << content_for(source, destination)
          git_ignore_if_needed(file.path)
        end
      end
    end
  end

  private
    def needs_update?(source, destination)
      !File.exists?(destination) || File.mtime(source) > File.mtime(destination)
    end

    def content_for(source, destination)
      parsed = parse_meta_data(File.read(source))

      if template?
        template(parsed)
      else
        formatter_for(source).call(parsed[:content])
      end
    end

    def formatter_for(file_name)
      config[File.extname(file_name)[1..-1].to_sym]
    end

    def files_list
      `git ls-files`.split("\n").select { |file_name| include?(file_name) }
    end

    def include?(file_name)
      file_name !~ Regexp.union(*(config[:excludes] || [])) &&
        config[:extensions].map(&:to_s).include?(File.extname(file_name)[1..-1])
    end

    def template(variables)
      formatter_for(config[:template]).call(load_template_file, variables)
    end

    def template?
      load_template_file
    end

    def load_template_file
      @template_content ||= begin
        File.read(File.join(options[:directory], config[:template]))
      rescue Errno::ENOENT
        nil
      end
    end

    def config
      @config = begin
        YAML.load_file(options[:config] || 'statig.yml')
      rescue Errno::ENOENT
        abort "Couldn't load configuration file"
      end
    end

    def parse_meta_data(string)
      parsed = {:meta_data => [], :content => string}
      return parsed unless string =~ /((\w[\w\s]+: .*\n)+)\n/

      parsed.update(:content => $')
      meta_data = $1.split("\n").inject({}) do |meta_data, line|
        parts = line.split(':', 2)
        key   = parts.first.strip.downcase.to_sym
        value = parts.last.strip
        meta_data.update(key => value)
      end

      parsed.update(:meta_data => meta_data)
    end

    def git?
      `git status &> /dev/null`
      $?.exitstatus.to_i == 1
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
end
