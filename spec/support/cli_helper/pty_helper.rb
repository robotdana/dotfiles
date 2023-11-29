require 'pty'
require 'shellwords'
require 'timeout'

require_relative 'pty_status'
require_relative 'io_string_methods'

module CLIHelper
  class << self
    attr_accessor :default_max_wait_time
  end

  self.default_max_wait_time = 2

  module PTYHelper
    def rake(*task, &block)
      run("rake", "-f", "#{__dir__}/../../Rakefile", *task, &block)
    end

    # def insert_pre_pty(cmd)
      # cmd, args = cmd.split(' ', 2)
      # "#{cmd} -r./spec/support/pre_pty.rb #{args}"
    # end

    def define_stderr
      return if defined?(@stderr) && defined?(@stderr_writer)

      @stderr, @stderr_writer = IO.pipe
      @stderr.extend(StringIOStringMethods)
      @stderr.extend(IOStringMethods)
    end

    def stderr
      @stderr || define_stderr && stderr
    end

    def stderr_writer
      @stderr_writer || define_stderr && stderr_writer
    end

    def define_stdout
      return if defined?(@stdout) && defined?(@stdout_writer)

      @stdout, @stdout_writer = IO.pipe
      @stdout.extend(StringIOStringMethods)
      @stdout.extend(IOStringMethods)
    end

    def stdout
      @stdout || define_stdout && stdout
    end

    def stdout_writer
      @stdout_writer || define_stdout && stdout_writer
    end

    attr_reader :status

    def run(cmd, *cmd_args, env: {}, wait: CLIHelper.default_max_wait_time, **spawn_kwargs, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      Timeout.timeout(wait) { true while running? }

      env = self.env.merge(env.transform_keys(&:to_s))

      spawn_args = [env, cmd, *cmd_args]
      spawn_kwargs = {
        err: stderr_writer.fileno,
        out: stdout_writer.fileno,
        chdir: Dir.pwd,
        unsetenv_others: true,
        **spawn_kwargs
      }

      if block_given?
        begin
          PTY.spawn(*spawn_args, **spawn_kwargs) do |_, stdin, pid|
            @status = PTYStatus.new(pid)
            @stdin&.close # close existing
            @stdin = stdin

            block.call(stdin)
          end
        ensure
          @stdin&.puts('exit')
          begin
            @status
          ensure
            @stdin&.close
            @stdin = nil
          end
        end
        @status
      else
        @stdin&.close
        _, @stdin, pid = PTY.spawn(*spawn_args, **spawn_kwargs)
        @status = PTYStatus.new(pid)
      end
    end

    def running?
      @status&.running?
    end

    def self.write_env_to_pty(env = {}, stdin)
      env.each do |key, value|
        stdin.puts("export #{Shellwords.escape(key)}=#{Shellwords.escape(value)}")
      end
    end

    def env(values_to_merge = {})
      @env ||= Bundler.original_env.dup.freeze
      return @env if values_to_merge.empty?

      @env = @env.merge(values_to_merge.transform_keys(&:to_s)).freeze
      PTYHelper.write_env_to_pty(values_to_merge, @stdin) if running?
    end

    def pty_output_cleanup
      @stdin&.close
      @stdout&.close
      @stdout_writer&.close
      @stderr&.close
      @stderr_writer&.close
    end
  end
end

RSpec.configure do |config|
  config.include CLIHelper::PTYHelper
  config.after do
    pty_output_cleanup
  end
end
