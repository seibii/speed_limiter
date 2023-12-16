# frozen_string_literal: true

require "speed_limiter/state"

module SpeedLimiter
  # Throttle params model
  class ThrottleParams
    def initialize(config:, key:, limit:, period:, on_throttled: nil)
      @config = config
      @key = key
      @limit = limit
      @period = period
      @on_throttled = on_throttled
    end

    attr_reader :config, :key, :limit, :period, :on_throttled

    def redis_key
      "#{config.prefix}:#{key}"
    end

    def create_state(count: nil, ttl: nil)
      State.new(params: self, count: count, ttl: ttl)
    end
  end
end
