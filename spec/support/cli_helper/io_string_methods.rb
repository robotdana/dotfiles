# frozen_string_literal: true

require 'tty_string'
require_relative 'eventually'

module CLIHelper
  module StringIOStringMethods
    def ==(other)
      to_s == other
    end

    def to_s
      TTYString.new(string, clear_style: false).to_s
    end

    def to_str
      to_s
    end

    def inspect
      string.inspect
    end

    def empty?
      string.empty?
    end

    def each_line(&block)
      to_s.each_line(&block)
    end

    def readlines
      string.each_line.to_a
    end

    def clear
      string.truncate(0)
    end
  end

  module IOStringMethods
    def string(wait: CLIHelper.default_max_wait_time)
      @string ||= ''
      Eventually.satisfy(wait: wait) do
        @string += read_nonblock(4096)
        true
      rescue IO::WaitReadable
        true unless readable? && retry
      rescue Errno::EIO, IOError
        true
      end
      @string
    end

    def readable?
      IO.select([self], nil, nil, 0)
    end

    def empty?
      sleep 0.5
      string.empty?
    end

    def clear
      sleep 0.5
      string.replace('')
    end
  end
end
