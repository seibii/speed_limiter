# frozen_string_literal: true

require "speed_limiter/version"
require "speed_limiter/config"
require "speed_limiter/throttle"
require "redis"

# Call speed limiter
module SpeedLimiter
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end

    # @param key [String] key name
    # @param limit [Integer] limit count per period
    # @param period [Integer] period time (seconds)
    # @param on_throttled [Proc] Block called when limit exceeded, with ttl(Float) and key as argument
    # @yield [count] Block called to not reach limit
    # @yieldparam count [Integer] count of period
    # @yieldreturn [any] block return value
    def throttle(key, **params, &block)
      Throttle.new(config: config, key: key, **params, &block).throttle
    end
  end
end
