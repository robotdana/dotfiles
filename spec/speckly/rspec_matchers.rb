# frozen_string_literal: true

require 'shellwords'

module Speckly
  NO_ARG = Object.new
  private_constant :NO_ARG
end

require_relative 'rspec/have_exitstatus'
require_relative 'rspec/have_output'
