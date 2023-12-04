# frozen_string_literal: true

require_relative 'speckly/api'
require_relative 'speckly/command'
require_relative 'speckly/concat_io'
require_relative 'speckly/io'
require_relative 'speckly/session'
require_relative 'speckly/eventually'

module Speckly # rubocop:disable Metrics
  @original_working_directory = Dir.pwd
  @default_env = defined?(Bundler) ? Bundler.original_env.dup : ENV.to_h
  @default_debug_login_shell = 'bash -l' # TODO: guess which shell they use; https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
  @default_max_wait_time = 2
  @default_command_prefix = []

  class << self
    attr_writer :default_env, :default_max_wait_time, :default_command_prefix
    attr_accessor :original_working_directory, :current_session, :default_debug_login_shell

    def default_env
      @default_env ||= defined?(Bundler) ? ::Bundler.original_env.dup : ENV.to_h.dup
    end

    def default_max_wait_time
      @default_max_wait_time ||= 2
    end

    def default_command_prefix
      @default_command_prefix ||= []
    end
  end

  module_function

  def session # rubocop:disable Metrics
    if block_given?
      begin
        Speckly.current_session = Session.new(Speckly.current_session)
        yield
      ensure
        Speckly.current_session = Speckly.current_session.pop
      end
    else
      Speckly.current_session = Speckly.current_session || Session.new
    end
  end

  def cleanup_session
    Speckly.current_session&.cleanup
    Speckly.current_session = nil
  end

  def run_command( # rubocop:disable Metrics
    cmd,
    *,
    exit_with: 0,
    wait: Speckly.default_max_wait_time,
    anywhere: false,
    chdir: Speckly.session.dir,
    **
  )
    chdir = Speckly.path(chdir, anywhere:)
    command = Command.new(cmd, *, chdir:, **)
    Speckly.session.commands << command
    ::Dir.chdir(chdir) { yield command } if block_given?

    expect(command).to have_exitstatus(exit_with, wait:) if exit_with
    command
  end
  alias_method :run, :run_command

  def debug(new_login_shell_command = Speckly.default_debug_login_shell) # rubocop:disable Metrics
    ::Process.wait ::Process.spawn(
      ::Speckly.default_env,
      new_login_shell_command,
      chdir: Speckly.session.dir,
      unsetenv_others: true
    )
  end

  def create_file(*lines, path:, anywhere: false) # rubocop:disable Metrics
    path = Speckly.path(path, anywhere:)
    path.parent.mkpath

    if lines.empty?
      path.write('') unless path.exist?
    elsif path.exist?
      raise Errno::EEXIST unless path.read == "#{lines.join("\n")}\n"
    else
      path.write("#{lines.join("\n")}\n")
    end

    path
  end

  def path(relative_path, anywhere: false)
    path = ::File.expand_path(relative_path, session.dir)

    if anywhere && !Speckly.session.within_temp_dir?(path)
      raise ArgumentError,
            "#{path} isn't within a temp directory created by Speckly"
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

  def copy_file(*relative_paths, anywhere: false) # rubocop:disable Metrics
    relative_paths.each do |relative_path|
      dest = Speckly.path(relative_path, anywhere:)
      dest.parent.mkpath
      ::FileUtils.cp_r(
        ::File.expand_path(relative_path, ::Speckly.original_working_directory),
        dest.to_s
      )
    end
  end

  def create_dir(path, anywhere: false, &block)
    Speckly.path(path, anywhere:).mkpath
    return path unless block_given?

    Dir.chdir(path, &block)
  end

  def create_symlink(hash, anywhere: false)
    hash.each do |link, target|
      link_path = Speckly.path(link, anywhere:)
      link_path.parent.mkpath

      FileUtils.ln_s(Speckly.path(target, anywhere: true), link_path.to_s)
    end
  end

  def create_file_list(*filenames, anywhere: false)
    filenames.each do |filename|
      Speckly.create_file(filename, path: filename, anywhere:)
    end
  end
end
