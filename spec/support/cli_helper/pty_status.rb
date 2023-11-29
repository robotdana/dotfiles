require 'timeout'

module CLIHelper
  class PTYStatus
    def initialize(pid)
      @pid = pid
    end

    attr_reader :pid

    def ==(other)
      exitstatus! == other
    end
    alias_method :eql?, :==

    def status(wait: CLIHelper.default_max_wait_time)
      @status ||= Timeout.timeout(wait) do
        Process::Status.wait(@pid)
      rescue Timeout::Error
        nil
      end
    end

    def status!(wait: CLIHelper.default_max_wait_time)
      @status ||= Timeout.timeout(wait - 0.5) do
        Process::Status.wait(@pid)
      rescue Timeout::Error
        Process.kill("KILL", @pid)
        status(wait: 0.5)
      end
    end

    def running?
      (@status ||= PTY.check(@pid)).nil?
    end

    def coredump?
      status.coredump?
    end

    def exited?
      status.exited?
    end

    def exitstatus
      status.exitstatus
    end

    def exitstatus!
      status!.exitstatus
    end

    def inspect
      status.inspect
    end

    def signaled?
      status.signaled?
    end

    def stopped?
      status.stopped?
    end

    def stopsig
      status.stopsig
    end

    def success?
      status.success?
    end

    def termsig
      status.termsig
    end

    def inspect
      status&.inspect&.sub('Process::Status', self.class.name) || super
    end
  end
end
