require_relative 'speckly/api'
require_relative 'speckly/command'
require_relative 'speckly/io'
require_relative 'speckly/session'
require_relative 'speckly/eventually'


module Speckly
  @original_working_directory = Dir.pwd

  @default_env = (Bundler ? ::Bundler.original_env.dup : ENV.to_h)
  @default_max_wait_time = 2
  @default_command_prefix = []

  class << self
    attr_writer :default_env
    attr_writer :default_max_wait_time
    attr_writer :default_command_prefix
    attr_accessor :original_working_directory

    def default_env
      @default_env ||= defined?(Bundler) ? ::Bundler.original_env.dup : ENV.to_h.dup
    end

    def default_max_wait_time
      @default_max_wait_time ||= 2
    end

    def default_command_prefix
      @default_command_prefix ||= []
    end

    attr_accessor :current_session
  end

  module_function

  def session
    if !block_given?
      Speckly.current_session = Speckly.current_session || Session.new
    else
      begin
        Speckly.current_session = Session.new(Speckly.current_session)
        yield
      ensure
        Speckly.current_session = Speckly.current_session.pop
      end
    end
  end

  def cleanup_session
    Speckly.current_session&.cleanup
    Speckly.current_session = nil
  end

  def run_command(cmd, *args, expect_exit: 0, anywhere: false, chdir: Speckly.session.dir, **kwargs)
    chdir = Speckly.path(chdir, anywhere: anywhere)
    command = Command.new(cmd, *args, chdir: chdir, **kwargs)

    Speckly.session.commands << command
    Speckly.session.chdir(chdir) { yield command } if block_given?

    expect(command).to have_exitstatus(expect_exit) if expect_exit
    command
  end
  alias_method :run, :run_command

  def create_file(*lines, path:, anywhere: false)
    path = Speckly.path(path, anywhere: anywhere)
    path.parent.mkpath

    if lines.empty?
      path.write('') unless path.exist?
    else
      if path.exist?
        raise Errno::EEXIST unless path.read == lines.join("\n") + "\n"
      else
        path.write(lines.join("\n") + "\n")
      end
    end

    path
  end

  def path(relative_path, anywhere: false)
    path = ::File.expand_path(relative_path, session.dir)

    if anywhere && !Speckly.session.within_temp_dir?(path)
      raise ArgumentError, "#{path} isn't within a temp directory created by Speckly"
    end

    ::Pathname.new(path)
  end
  alias_method :file, :path

  def stdout
    Speckly.session.stdout
  end

  def stderr
    Speckly.session.stderr
  end

  def copy_file(*relative_paths, anywhere: false)
    relative_paths.each do |relative_path|
      dest = Speckly.path(relative_path, anywhere: anywhere)
      dest.parent.mkpath
      ::FileUtils.cp_r(
        ::File.expand_path(relative_path, ::Speckly.original_working_directory),
        dest.to_s
      )
    end
  end


  def create_dir(path, anywhere: false, &block)
    Speckly.path(path, anywhere: anywhere).mkpath
    return path unless block_given?

    Dir.chdir(path, &block)
  end

  def create_symlink(hash, anywhere: false)
    hash.each do |link, target|
      link_path = Speckly.path(link, anywhere: anywhere)
      link_path.parent.mkpath

      FileUtils.ln_s(Speckly.path(target, anywhere: true), link_path.to_s)
    end
  end

  def create_file_list(*filenames, anywhere: false)
    filenames.each do |filename|
      Speckly.create_file(filename, path: filename, anywhere: anywhere)
    end
  end
end
