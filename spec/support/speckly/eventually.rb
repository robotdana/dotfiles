# frozen_string_literal: true

require 'timeout'

module Speckly
  module Eventually
    class << self
      def satisfy(wait: Speckly.default_max_wait_time, break_if_stopped: nil, &block)
        Timeout.timeout(wait + 1) do
          start_time = monotonic_time
          end_time = start_time + (wait)
          until end_time < monotonic_time
            result = block.call
            return true if result
            # return result if break_if_stopped&.stopped?
            sleep(rand / 10)
          end
        end
      rescue Timeout::Error
        false
      end

      private

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
