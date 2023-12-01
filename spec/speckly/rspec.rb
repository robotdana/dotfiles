require_relative '../speckly'
require_relative 'rspec_matchers'

RSpec.configure do |config|
  config.prepend Speckly
  config.after do
    Speckly.cleanup_session
  end
end
