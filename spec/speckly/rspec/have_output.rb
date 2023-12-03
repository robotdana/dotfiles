# frozen_string_literal: true

require 'shellwords'
require 'tty_string'
require 'English'

module Speckly # rubocop:disable Metrics/ModuleLength
  ::RSpec::Matchers.define_negated_matcher(:be_present, :be_empty) unless ''.respond_to?(:present?)

  ::RSpec::Matchers.define :have_output do | # rubocop:disable Metrics/ParameterLists
      merged = NO_ARG,
      stdout: NO_ARG,
      stderr: NO_ARG,
      rendered: false,
      split: false,
      wait: Speckly.default_max_wait_time
    |
    match do |command|
      unless command.respond_to?(:output) &&
          command.respond_to?(:stdout) &&
          command.respond_to?(:stderr) &&
          command.respond_to?(:merged?)
        raise ArgumentError, 'Must be a Speckly::Command or a Speckly::Session'
      end

      @command = command
      prepare_matchers(command, merged, stdout, stderr)
      prepare_value_transformer(rendered, split)

      Speckly::Eventually.satisfy(wait:) do
        (!@expected_merged || (@passed_merged = values_match?(@expected_merged, (@actual_merged = @transform_value.call(actual.output))))) && # rubocop:disable Layout/LineLength
          (!@expected_stdout || (@passed_stdout = values_match?(@expected_stdout, (@actual_stdout = @transform_value.call(actual.stdout))))) && # rubocop:disable Layout/LineLength
          (!@expected_stderr || (@passed_stderr = values_match?(@expected_stderr, (@actual_stderr = @transform_value.call(actual.stderr))))) # rubocop:disable Layout/LineLength
      end || prepare_result_for_diff
    end

    match_when_negated do |command|
      unless merged == NO_ARG && stdout == NO_ARG && stderr == NO_ARG
        raise ArgumentError,
              'negated have_output with a value is not available'
      end
      unless command.respond_to?(:output)
        raise ArgumentError,
              'must be a Speckly::Command or a Speckly::Session'
      end

      @command = command
      sleep 0.1
      values_match?((@expected_merged = be_empty),
                    (@actual_merged = actual.output.to_s))
    end

    failure_message do
      message = +''
      if @passed_merged == false
        message << prepare_failure_message(
          :output, @expected_merged, @actual_merged
        )
      end
      if @passed_stdout == false
        message << prepare_failure_message(
          :stdout, @expected_stdout, @actual_stdout
        )
      end
      if @passed_stderr == false
        message << prepare_failure_message(
          :stderr, @expected_stderr, @actual_stderr
        )
      end
      message.chomp
    end

    failure_message_when_negated do
      "expected #{@command} to not have output.\ngot:\n#{@actual_merged}"
    end

    diffable

    private

    def prepare_failure_message(stream, expected, actual)
      <<~MESSAGE
        expected #{@command} to have #{stream}:
        #{expected}

        got:
        #{actual}

      MESSAGE
    end

    def prepare_value_transformer(rendered, split) # rubocop: disable Metrics/MethodLength
      split = $INPUT_RECORD_SEPARATOR if split == true
      clear_style = true if rendered != :keep_style

      @transform_value = if rendered && split
        ->(s) { TTYString.parse(s.to_s, clear_style:).split(split) }
      elsif rendered
        ->(s) { TTYString.parse(s.to_s, clear_style:) }
      elsif split
        ->(s) { s.to_s.split(split) }
      else
        :to_s.to_proc
      end
    end

    def prepare_result_for_diff # rubocop:disable Metrics/MethodLength
      @expected, @actual = if @expected_merged
        [@expected_merged, @actual_merged]
      elsif @expected_stdout && @expected_stderr
        [[@expected_stdout, @expected_stderr], [@actual_stdout, @actual_stderr]]
      elsif @expected_stdout
        [@expected_stdout, @actual_stdout]
      else
        [@expected_stderr, @actual_stderr]
      end

      false
    end

    def prepare_matchers(command, merged, stdout, stderr) # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
      if command.merged? && (stdout != NO_ARG || stderr != NO_ARG)
        raise ArgumentError, 'command was run with `merged_output: true` ' \
                             "so can't match stdout and stderr separately"
      elsif merged != NO_ARG && (stdout != NO_ARG || stderr != NO_ARG)
        raise ArgumentError, "can't use a merged matcher and single stream " \
                             'matchers together'
      elsif merged == NO_ARG && stdout == NO_ARG && stderr == NO_ARG
        @expected_merged = be_present
      elsif stdout == NO_ARG && stderr == NO_ARG
        @expected_merged = io_matcher(merged)
      elsif stdout != NO_ARG && stderr != NO_ARG
        @expected_stdout = io_matcher(stdout)
        @expected_stderr = io_matcher(stderr)
      elsif stdout != NO_ARG
        @expected_stdout = io_matcher(stdout)
      elsif stderr != NO_ARG
        @expected_stderr = io_matcher(stderr)
      else
        raise ArgumentError, 'Unexpected argument combination'
      end
    end

    def io_matcher(arg) # rubocop:disable Metrics/MethodLength
      if arg == NO_ARG || arg == true
        be_present
      elsif arg
        arg
      else
        be_empty
      end
    end
  end
end
