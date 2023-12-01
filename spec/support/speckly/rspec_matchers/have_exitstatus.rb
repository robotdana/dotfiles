require 'shellwords'

module Speckly
  RSpec::Matchers.define :have_exitstatus do |expected = NO_ARG, wait: Speckly.default_max_wait_time|
    match do |actual|
      if expected == NO_ARG
        has_any_exitstatus?(actual, wait: wait)
      else
        has_any_exitstatus?(actual, wait: wait) && values_match?(expected, actual.exitstatus)
      end
    end

    match_when_negated do |actual|
      if expected == NO_ARG
        !actual.exitstatus
      else
        has_any_exitstatus?(actual, wait: wait) && !values_match?(expected, actual.exitstatus)
      end
    end

    failure_message do
      if expected == NO_ARG
        "expected run #{Shellwords.join(actual.command).inspect} to have an exitstatus"
      elsif actual.exitstatus.nil?
        "expected run #{Shellwords.join(actual.command).inspect} to have exitstatus=#{expected}, has no exitstatus"
      else
        "expected run #{Shellwords.join(actual.command).inspect} to have exitstatus=#{expected}, has exitstatus=#{actual.exitstatus}"
      end
    end

    failure_message_when_negated do
      if expected == NO_ARG
        "expected run #{Shellwords.join(actual.command).inspect} to not have an exitstatus, has exitstatus=#{actual.exitstatus}"
      else
        "expected run #{Shellwords.join(actual.command).inspect} to not have exitstatus=#{expected}"
      end
    end

    private

    def has_any_exitstatus?(actual, wait:)
      Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
        actual.exitstatus
      end
    end
  end
end
