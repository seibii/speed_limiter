# frozen_string_literal: true

require "speed_limiter/errors/limit_exceeded_error"

module SpeedLimiter
  module Errors
    # SpeedLimiter::Throttled limit exceeded Error
    class ThrottledError < LimitExceededError
    end
  end
end
