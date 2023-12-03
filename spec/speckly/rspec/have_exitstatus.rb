# frozen_string_literal: true

require 'shellwords'

module Speckly
  RSpec::Matchers.define :have_exitstatus do |expected = NO_ARG, wait: Speckly.default_max_wait_time|
    match do |actual|
      if expected == NO_ARG
        has_any_exitstatus?(actual, wait:)
      else
        has_any_exitstatus?(actual, wait:) && values_match?(expected, actual.exitstatus)
      end
    end

    match_when_negated do |actual|
      if expected == NO_ARG
        !actual.exitstatus
      else
        has_any_exitstatus?(actual,
                            wait:) && !values_match?(expected,
                                                     actual.exitstatus)
      end
    end

    failure_message do
      if expected == NO_ARG
        "expected run #{command_s} to have an exitstatus\n" \
          "output:\n#{actual.output}\n"
      elsif actual.exitstatus.nil?
        "expected run #{command_s} to have exitstatus=#{expected}, " \
          "has no exitstatus\noutput:\n#{actual.output}\n"
      else
        "expected run #{command_s} to have exitstatus=#{expected}, " \
          "has exitstatus=#{actual.exitstatus}\noutput:\n#{actual.output}\n"
      end
    end

    failure_message_when_negated do
      if expected == NO_ARG
        "expected run #{command_s} to not have an exitstatus, " \
          "has exitstatus=#{actual.exitstatus}"
      else
        "expected run #{command_s} to not have exitstatus=#{expected}"
      end
    end

    private

    def command_s
      Shellwords.join(actual.command).inspect
    end

    def has_any_exitstatus?(actual, wait:)
      Speckly::Eventually.satisfy(wait:) do
        actual.exitstatus
      end
    end
  end
end
