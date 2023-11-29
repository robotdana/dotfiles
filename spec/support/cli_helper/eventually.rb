# frozen_string_literal: true

require 'timeout'

module CLIHelper
  module Eventually
    class << self
      def equal?(value, wait: CLIHelper.default_max_wait_time)
        loop_within(wait) do
          output = yield
          return true if output == value
        end
        false
      end

      private

      def loop_within(wait)
        # timeout is just because it gets stuck sometimes
        Timeout.timeout(wait) do
          start_time = monotonic_time
          yield until start_time + (wait - 0.5) < monotonic_time
        end
      end

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
