# frozen_string_literal: true

module Speckly
  class ConcatIO
    def initialize(ios)
      @ios = ios
    end

    def to_s
      @ios.join
    end
  end
end
