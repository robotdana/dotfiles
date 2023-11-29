RSpec::Matchers.define :have_output do |expected|
  match do |actual|
    actual == expected # rubocop:disable Lint/Void i'm doing naughty things.

    @actual = actual.to_s
    expect(@actual).to eq(expected)
  end

  diffable
end

RSpec::Matchers.define :have_unordered_output do |expected|
  match do |actual|
    expected = expected.to_s.split("\n")
    if actual.is_a?(CLIHelper::IOStringMethods)
      CLIHelper::Eventually.equal?(expected, 4) { @actual == actual.to_s.split("\n").sort }
    end

    @actual ||= actual.to_s.split("\n")
    expect(@actual).to match_array(expected)
  end

  diffable
end
