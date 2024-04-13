# frozen_string_literal: true

module SpeedLimiter
  # config model
  class Config
    attr_accessor :redis_url, :redis, :no_limit, :prefix, :on_throttled

    def initialize
      @redis_url = ENV.fetch("SPEED_LIMITER_REDIS_URL", "redis://localhost:6379/0")
      @redis = nil
      @no_limit = false
      @prefix = "speed_limiter"
      @on_throttled = nil
    end

    alias no_limit? no_limit

    def redis_client
      @redis_client ||= SpeedLimiter::Redis.new(@redis || ::Redis.new(url: redis_url))
    end
  end
end
