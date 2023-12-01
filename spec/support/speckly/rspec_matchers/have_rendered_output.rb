require 'shellwords'

module Speckly
  RSpec::Matchers.define :have_rendered_output do |expected, clear_style: false, wait: Speckly.default_max_wait_time|
    match do |actual|
      @original_actual = actual
      @original_expected = expected

      Speckly::Eventually.satisfy(wait: wait, break_if_stopped: actual) do
        values_match?(expected, (@actual = TTYString.parse(actual.to_s, clear_style: clear_style)))
      end
    end

    failure_message do
      "expected #{original_actual.name} to have output=#{expected}, has output=#{actual}"
    end

    failure_message_when_negated do
      "expected run #{original_actual.name} to not have output=#{expected}, has output=#{actual}"
    end

    diffable

    private

    attr_reader :original_actual, :original_expected
  end
end
