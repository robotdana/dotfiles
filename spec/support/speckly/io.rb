require 'delegate'

module Speckly
  class IO
    class Pipe
      def initialize(name, command)
        reader, writer = ::IO.pipe(Encoding::BINARY, Encoding::BINARY, binmode: true)
        reader.set_encoding(Encoding::BINARY)
        writer.set_encoding(Encoding::BINARY)
        @name = name
        @command = command
        @reader = ::Speckly::IO.new(reader, name, command)
        @writer = ::Speckly::IO.new(writer, name, command)
      end

      attr_reader :reader, :writer, :name, :command

      def close
        @reader.close
      ensure
        @writer.close
      end
    end

    def self.pipe(name, command)
      Pipe.new(name, command)
    end

    attr_reader :name, :command

    def initialize(io, name, command)
      @io = io
      @name = name
      @command = command
    end

    def to_s(wait: Speckly.default_max_wait_time)
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

    def print(string, wait: Speckly.default_max_wait_time)
      writable?
      @io.print(string.dup.force_encoding(Encoding::BINARY))
      @io.flush
    end

    def puts(string, wait: Speckly.default_max_wait_time)
      writable?
      @io.puts(string.dup.force_encoding(Encoding::BINARY))
      @io.flush
    end

    def writable?
      ::IO.select(nil, [@io], nil, 0)
    end

    def readable?
      ::IO.select([@io], nil, nil, 0)
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
