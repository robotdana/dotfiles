RSpec::Matchers.define :eventually do |expected, wait: nil|
  wait ||= CLIHelper.default_max_wait_time
  match do |actual|
    CLIHelper::Eventually.satisfy(wait: wait) do
      @actual = actual.call

      values_match?(expected, @actual)
    end
  end

  supports_block_expectations
end

RSpec::Matchers.define :have_output do |expected|
  match do |actual|
    expect { actual.to_s }.to eventually(match(expected))
  end

  diffable
end

RSpec::Matchers.define :have_unordered_output do |expected|
  match do |actual|
    expected = expected.to_s.split("\n")
    expect { actual.to_s.split("\n") }.to eventually(match_array(expected))
  end

  diffable
end
