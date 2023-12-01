require 'tmpdir'

module Speckly
  class ConcatIO
    def initialize(commands, name)
      @commands = commands
      @name = name
    end

    def to_s
      @commands.map(&@name).join
    end

    def stopped?
      @commands.all?(&:stopped?)
    end

    attr_reader :name
  end

  class Session
    def initialize(parent: nil)
      @parent = parent
      @original_dir = ::Dir.pwd
      @commands = []
    end

    def pop
      close
      @parent
    end

    def dir
      @dir ||= Pathname.new(mktmpdir)
    end

    attr_reader :commands

    def chdir(dir, return_if: :block_given?)
      return_if = block_given? if return_if == :block_given?
      return_to = ::Dir.pwd if return_if
      dir = mktmpdir if dir == :temp
      @dir = Pathname.new(dir)
      yield if block_given?
    ensure
      chdir(return_to) if return_to
    end

    def cleanup
      ::Dir.chdir(@original_dir)
      commands.each(&:cleanup)
      @temp_dirs&.each { |dir| ::FileUtils.remove_dir(dir.to_s, true) if dir }
      @dir = nil
    end

    def within_temp_dir?(path)
      @temp_dirs.any? { |dir| path == dir || path.start_with?("#{dir}/") }
    end

    def stdout
      ConcatIO.new(commands, :stdout)
    end

    def stderr
      ConcatIO.new(commands, :stderr)
    end

    private

    def mktmpdir
      dir = ::Dir.mktmpdir
      @temp_dirs ||= []
      @temp_dirs << dir
      dir
    end
  end
end
