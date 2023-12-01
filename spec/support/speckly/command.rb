require 'pty'
require 'timeout'

module Speckly
  class Command
    def initialize(command, *args, chdir: ::Dir.pwd, env: {}, debug: false, **kwargs)
      @command = [*Speckly.default_command_prefix, command, *args]
      @env = Speckly.default_env.merge(env.transform_keys(&:to_s)).freeze
      @stdin = ::Speckly::IO.pipe(:stdin, self)
      @stdout = ::Speckly::IO.pipe(:stdout, self)
      @stderr = ::Speckly::IO.pipe(:stderr, self)
      _, _, @pid = ::PTY.spawn(
        @env,
        *Speckly.default_command_prefix,
        command,
        *args,
        unsetenv_others: true,
        in: (debug ? $stdin : @stdin.reader.fileno),
        out: (debug ? $stdout : @stdout.writer.fileno),
        err: (debug ? $stderr : @stderr.writer.fileno),
        chdir: chdir,
        **kwargs)
    end

    attr_reader :pid
    attr_reader :env
    attr_reader :command

    def stdin
      @stdin.writer
    end

    def stdout
      @stdout.reader
    end

    def stderr
      @stderr.reader
    end

    def cleanup
      @stdin&.close
    ensure
      begin
        @stdout&.close
      ensure
        begin
          @stderr&.close
        ensure
          kill! if running?
        end
      end
    end

    def status
      @status ||= ::PTY.check(@pid)
    end

    def status!(wait: ::Speckly.default_max_wait_time)
      ::Timeout.timeout(wait) do
        @status ||= ::Process::Status.wait(@pid)
      end
    end

    def kill!
      ::Process.kill(15, @pid)
    end

    def running?
      status.nil?
    end

    def coredump?
      status&.coredump?
    end

    def exited?
      status&.exited?
    end

    def exitstatus
      status&.exitstatus
    end

    def exitstatus!
      status!.exitstatus
    end

    def signaled?
      status&.signaled?
    end

    def stopped?
      status&.stopped?
    end

    def stopsig
      status&.stopsig
    end

    def success?
      status&.success?
    end

    def termsig
      status&.termsig
    end
  end
end
