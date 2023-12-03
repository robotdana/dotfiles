# frozen_string_literal: true

require 'delegate'

module Speckly
  class IO
    class Pipe
      def initialize
        reader, writer = ::IO.pipe(Encoding::BINARY, Encoding::BINARY, binmode: true)
        reader.set_encoding(Encoding::BINARY)
        writer.set_encoding(Encoding::BINARY)
        @reader = ::Speckly::IO.new(reader)
        @writer = ::Speckly::IO.new(writer)
      end

      attr_reader :reader, :writer

      def close
        @reader.close
      ensure
        @writer.close
      end
    end

    def self.pipe
      Pipe.new
    end

    def initialize(io)
      @io = io
    end

    def to_s
      buf << @io.read_nonblock(4096)
      buf
    rescue ::IO::WaitReadable
      buf unless readable? && retry
    rescue Errno::EIO, IOError
      buf
    end

    def stopped?
      command.stopped?
    end

    def inspect
      to_s.inspect
    end

    def print(string)
      writable?
      @io.print(string.dup.force_encoding(Encoding::BINARY))
      @io.flush
    end

    def puts(string)
      writable?
      @io.puts(string.dup.force_encoding(Encoding::BINARY))
      @io.flush
    end

    def writable?
      ::IO.select(nil, [@io], nil, 0) # rubocop:disable Lint/IncompatibleIoSelectWithFiberScheduler
    end

    def readable?
      ::IO.select([@io], nil, nil, 0) # rubocop:disable Lint/IncompatibleIoSelectWithFiberScheduler
    end

    def fileno
      @io.fileno
    end

    def close
      @io.close
    end

    private

    def buf
      @buf ||= +''.force_encoding(Encoding::BINARY)
    end

    def buf_to_s
      @buf.dup.force_encoding(Encoding.default_internal)
    end
  end
end
