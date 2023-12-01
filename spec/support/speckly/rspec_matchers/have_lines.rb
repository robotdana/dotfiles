module Speckly
  RSpec::Matchers.define :have_lines do |expected, wait: Speckly.default_max_wait_time|
    match do |actual|
      @original_expected = expected
      @original_actual = actual

      Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
        values_match?(expected, (@actual = actual.to_s).split("\n"))
      end
    end

    match_when_negated do |actual|
      @original_expected = expected
      @original_actual = actual

      if expected.respond_to?(:to_ary) && expected.all { |l| l.respond_to?(:to_str) }
        Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
          !values_match?(include(actual.to_s.map { |line| start_with(line) }), expected)
        end
        !values_match?(expected, (@actual = actual.to_s.split("\n")))
      else
        !Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
          values_match?(expected, (@actual = actual.to_s).split("\n"))
        end
      end
    end

    failure_message do
      "expected #{original_actual.name} to have output=#{expected}, has output=#{actual}"
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

    attr_reader :original_expected, :original_actual

    def has_any_output?(actual, wait:)
      Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) { actual.to_s }
    end
  end
end
