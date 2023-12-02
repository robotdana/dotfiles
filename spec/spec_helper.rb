# frozen_string_literal: true

if RUBY_PLATFORM != 'java'
  module Warning # leftovers:allow
    def warn(msg) # leftovers:allow
      raise msg
    end
  end
end

if RUBY_PLATFORM == 'java'
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
end

require 'fileutils'
FileUtils.rm_rf(File.join(__dir__, '..', 'coverage')) if ENV['COVERAGE']

require 'bundler/setup'

require 'simplecov' if ENV['COVERAGE']

require_relative 'speckly/rspec'
Speckly.default_max_wait_time = 10
Speckly.default_command_prefix = []

Dir.glob(::File.expand_path('support/**/*.rb', __dir__)).each do |file|
  require file
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
    c.max_formatted_output_length = nil
  end

  config.mock_with :rspec do |c|
    c.verify_partial_doubles = true
  end

  config.before do
    Kernel.srand config.seed
  end

  config.example_status_persistence_file_path = '.rspec_status'
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true
  config.disable_monkey_patching!
  config.order = :random

  Kernel.srand config.seed
end
