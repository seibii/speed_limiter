# frozen_string_literal: true

require "forwardable"
require "speed_limiter/redis"
require "speed_limiter/throttle_params"

module SpeedLimiter
  # with actual throttle limits
  class Throttle
    extend Forwardable

    # @param key [String, #to_s] Throttle key name
    # @option params [Integer] :limit limit count per period
    # @option params [Integer] :period period time (seconds)
    # @option params [Proc, #call] :on_throttled Block called when limit exceeded, with ttl(Float) and key as argument
    def initialize(key, config:, **params)
      params[:key] = key.to_s

      @config = config
      @params = ThrottleParams.new(config: config, **params)
    end
    attr_reader :config, :params, :block

    delegate %i[key redis_key limit period on_throttled create_state] => :params

    # @yield [state]
    # @yieldparam state [SpeedLimiter::State]
    # @return [any] block return value
    def call(&block)
      return block.call(create_state) if config.no_limit?

      loop do
        count, ttl = redis.increment(redis_key, period)

        break(block.call(create_state(count: count, ttl: ttl))) if count <= limit

        wait_for_interval(count)
      end
    end

    private

    def wait_for_interval(count)
      ttl = redis.ttl(redis_key)
      return if ttl.negative?

      config.on_throttled.call(create_state(count: count, ttl: ttl)) if config.on_throttled.respond_to?(:call)
      on_throttled.call(create_state(count: count, ttl: ttl)) if on_throttled.respond_to?(:call)

      ttl = redis.ttl(redis_key)
      return if ttl.negative?

      sleep ttl
    end

    def redis
      @redis ||= SpeedLimiter::Redis.new(config.redis || ::Redis.new(url: config.redis_url))
    end
  end
end
