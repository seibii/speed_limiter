# frozen_string_literal: true

module SpeedLimiter
  # config model
  class Config
    attr_accessor :redis_url, :redis, :no_limit, :prefix, :on_throttled

    def initialize
      @redis_url = "redis://localhost:6379/0"
      @redis = nil
      @no_limit = false
      @prefix = "speed_limiter"
      @on_throttled = nil
    end

    alias no_limit? no_limit
  end
end
