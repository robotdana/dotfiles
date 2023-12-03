# frozen_string_literal: true

require 'pty'
require 'timeout'

module Speckly
  class Command
    def initialize(command, *, merge_output: false, chdir: ::Dir.pwd, env: {}, **) # rubocop:disable Metrics
      @command = [*Speckly.default_command_prefix, command, *args]
      @env = ::Speckly.default_env.merge(env.transform_keys(&:to_s)).freeze
      @merge_output = merge_output
      @stdin = ::Speckly::IO.pipe
      @stdout = ::Speckly::IO.pipe
      @stderr = merge_output ? @stdout : ::Speckly::IO.pipe
      _, _, @pid = ::PTY.spawn(
        @env,
        *Speckly.default_command_prefix,
        command,
        *,
        unsetenv_others: true,
        in: @stdin.reader.fileno,
        out: @stdout.writer.fileno,
        err: @stderr.writer.fileno,
        chdir:,
        **
      )
    end

    attr_reader :pid, :env, :command

    def merged?
      @merge_output
    end

    def output
      merged? ? @stdout.reader : ConcatIO.new([@stdout.reader, @stderr.reader])
    end

    def stdin
      @stdin.writer
    end

    def stdout
      @stdout.reader
    end

    def stderr
      @stderr.reader
    end

    def cleanup # rubocop:disable Metrics
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
