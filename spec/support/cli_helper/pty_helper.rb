require 'pty'
require 'shellwords'
require 'timeout'

require_relative 'pty_status'
require_relative 'io_string_methods'

module CLIHelper
  class Output
    def initialize(parent = nil)
      @parent = parent
    end

    attr_accessor :status

    def close
      @stdout_reader&.close
      @stdout_writer&.close
      @stderr_reader&.close
      @stderr_writer&.close
      @stdin_writer&.close
      @stdin_reader&.close
    end

    def pop
      @parent
    end

    def stderr_reader
      @stderr_reader || define_stderr && stderr_reader
    end

    def stderr_writer
      @stderr_writer || define_stderr && stderr_writer
    end

    def stdout_reader
      @stdout_reader || define_stdout && stdout_reader
    end

    def stdout_writer
      @stdout_writer || define_stdout && stdout_writer
    end

    def stdin_reader
      @stdin_reader || define_stdin && stdin_reader
    end

    def stdin_writer
      @stdin_writer || define_stdin && stdin_writer
    end

    private

    def define_stderr
      return if defined?(@stderr_reader) && defined?(@stderr_writer)

      @stderr_reader, @stderr_writer = IO.pipe
      @stderr_reader.extend(StringIOStringMethods)
      @stderr_reader.extend(IOStringMethods)
    end

    def define_stdin
      return if defined?(@stdin_reader) && defined?(@stdin_writer)

      @stdin_reader, @stdin_writer = IO.pipe
      @stdin_reader.extend(StringIOStringMethods)
      @stdin_reader.extend(IOStringMethods)
    end

    def define_stdout
      return if defined?(@stdout_reader) && defined?(@stdout_writer)

      @stdout_reader, @stdout_writer = IO.pipe
      @stdout_reader.extend(StringIOStringMethods)
      @stdout_reader.extend(IOStringMethods)
    end
  end

  class << self
    attr_accessor :default_max_wait_time
  end

  self.default_max_wait_time = 2

  module PTYHelper
    def rake(*task, &block)
      run("rake", "-f", "#{__dir__}/../../Rakefile", *task, &block)
    end

    def output
      if !block_given?
        @output ||= Output.new
      else
        begin
          @output = Output.new(output)
          yield
        ensure
          @output.close
          @output = @output.pop
        end
      end
    end

    def stdout
      output.stdout_reader
    end

    def stderr
      output.stderr_reader
    end

    def stdin
      output.stdin_writer
    end

    def status
      output.status
    end

    def run(cmd, *cmd_args, env: {}, expect_exit: 0, wait: CLIHelper.default_max_wait_time, **spawn_kwargs, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      Timeout.timeout(wait) { true while running? }

      env = self.env.merge(env.transform_keys(&:to_s))

      spawn_args = [env, cmd, *cmd_args]
      spawn_kwargs = {
        err: output.stderr_writer.fileno,
        out: output.stdout_writer.fileno,
        in: output.stdin_reader,
        chdir: Dir.pwd,
        unsetenv_others: true,
        **spawn_kwargs
      }

      if block_given?
        begin
          Process.spawn(*spawn_args, **spawn_kwargs) do |_, _, pid|
            output.status = PTYStatus.new(pid)

            block.call(stdin)
          end
        end
      else
        _, _, pid = Process.spawn(*spawn_args, **spawn_kwargs)
        output.status = PTYStatus.new(pid)
      end
      expect(status).to eq(expect_exit) if expect_exit
      status
    end

    def running?
      status&.running?
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
      @output&.close
    end
  end
end

RSpec.configure do |config|
  config.include CLIHelper::PTYHelper
  config.after do
    pty_output_cleanup
  end
end
