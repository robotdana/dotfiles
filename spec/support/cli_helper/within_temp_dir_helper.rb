# frozen_string_literal: true

require 'pathname'
require 'tmpdir'
require 'fileutils'
require 'delegate'

module CLIHelper
  module WithinTempDir; end
  class WithinTempDirDelegator < SimpleDelegator; end


  module WithinTempDirHelper
    module ClassMethods
      def within_temp_dir(keep: false, &block)
        if block_given?
          context("within temp dir") do
            within_temp_dir(keep: keep)

            block.call
          end
        else
          around { |e| within_temp_dir(keep: keep) { e.run } }
        end
      end
    end

    def within_temp_dir(keep: false, &block)
      dir = Pathname.new(Dir.mktmpdir)
      if block_given?
        begin
          Dir.chdir(dir) do
            delegator = Class.new(SimpleDelegator)
            delegator.include(WithinTempDir)
            delegator.new(self).instance_eval(&block)
          end
        ensure
          ::FileUtils.remove_dir(dir.to_s, true) if dir && !keep
        end
      else
        extend WithinTempDir
        return dir if keep

        @__within_temp_dir_dirs_to_clean_up ||= []
        @__within_temp_dir_dirs_to_clean_up << dir
      end
    end
  end

  module WhenWithinTempDirHelper
    # already within temp dir
    def within_temp_dir
      yield if block_given?
    end
  end
end

RSpec.configure do |config|
  config.include CLIHelper::WithinTempDirHelper
  config.extend CLIHelper::WithinTempDirHelper::ClassMethods
  config.after(:example) do
    @__within_temp_dir_dirs_to_clean_up&.each do |dir|
      ::FileUtils.remove_dir(dir.to_s, true) if dir
    end
  end
end

CLIHelper::WithinTempDir.include(CLIHelper::WhenWithinTempDirHelper)

