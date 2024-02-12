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

    # @param key (see Throttle#initialize)
    # @option (see Throttle#initialize)
    # @yield (see Throttle#call)
    # @yieldparam (see Throttle#call)
    # @return Return value of block if argument contains block, otherwise Throttle instance
    def throttle(key, **params, &block)
      throttle = Throttle.new(key, config: config, **params)

      if block
        throttle.call(&block)
      else
        throttle
      end
    end
  end
end
