require 'shellwords'

module Speckly
  NO_ARG = Object.new
  private_constant :NO_ARG
end

require_relative 'rspec_matchers/have_exitstatus'
require_relative 'rspec_matchers/have_output'
require_relative 'rspec_matchers/have_lines'
require_relative 'rspec_matchers/have_rendered_output'
require_relative 'rspec_matchers/have_rendered_lines'


