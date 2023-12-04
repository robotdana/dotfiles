# frozen_string_literal: true

require 'tmpdir'

module Speckly
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

    def cleanup
      ::Dir.chdir(@original_dir)
      commands.each(&:cleanup)
      @temp_dirs&.each { |dir| ::FileUtils.remove_dir(dir.to_s, true) if dir }
      @dir = nil
    end

    def within_temp_dir?(path)
      @temp_dirs.any? { |dir| path == dir || path.start_with?("#{dir}/") }
    end

    def merged?
      false
    end

    def output
      ConcatIO.new(commands.map(&:merged))
    end

    def stdout
      ConcatIO.new(commands.map(&:stdout))
    end

    def stderr
      ConcatIO.new(commands.map(&:stderr))
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
