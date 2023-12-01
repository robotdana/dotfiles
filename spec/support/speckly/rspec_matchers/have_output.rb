require 'shellwords'

module Speckly
  RSpec::Matchers.define :have_output do |expected = NO_ARG, wait: Speckly.default_max_wait_time|
    match do |actual|
      @original_actual = actual
      @original_expected = expected

      if expected == NO_ARG
        @actual = actual.to_s
        has_any_output?(actual, wait: wait)
      else
        Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
          values_match?(expected, (@actual = actual.to_s))
        end
      end
    end

    match_when_negated do |actual|
      @original_actual = actual
      @original_expected = expected

      if expected == NO_ARG
        sleep 0.1

        @actual = actual.to_s
        @actual.empty?
      elsif expected.respond_to?(:to_str)
        Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
          !expected.to_str.start_with?(@actual = actual.to_s)
        end
        expected == actual.to_s
      else
        !Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
          values_match?(expected, (@actual = actual.to_s))
        end
      end
    end

    failure_message do
      if original_expected == NO_ARG
        "expected #{original_actual.name} to have output"
      else
        "expected #{original_actual.name} to have output=#{expected}, has output=#{actual}"
      end
    end

    failure_message_when_negated do
      if original_expected == NO_ARG
        "expected run #{original_actual.name} to not have output, has output=#{actual}"
      else
        "expected run #{original_actual.name} to not have output=#{expected}, has output=#{actual}"
      end
    end

    diffable

    private

    attr_reader :original_actual, :original_expected

    def has_any_output?(actual, wait:)
      Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) { actual.to_s.length > 0 }
    end
  end
end
