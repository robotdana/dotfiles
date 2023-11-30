# frozen_string_literal: true

require 'timeout'

module CLIHelper
  module Eventually
    class << self
      def satisfy(wait: CLIHelper.default_max_wait_time)
        Timeout.timeout(wait) do
          loop_within(wait) do
            Timeout.timeout(wait) do
              return true if yield
            end
          end

          false
        end
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
