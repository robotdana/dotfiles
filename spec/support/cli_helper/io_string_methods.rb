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
  end

  module IOStringMethods
    def string
      @string ||= ''
      @string += read_nonblock(4096)
    rescue IO::WaitReadable
      (readable? && retry) || @string
    rescue Errno::EIO, IOError
      @string
    end

    def ==(other)
      Eventually.equal?(other) { to_s }
    end

    def readable?
      IO.select([self], nil, nil, 0)
    end

    def empty?
      sleep 0.1
      string.empty?
    end
  end
end
