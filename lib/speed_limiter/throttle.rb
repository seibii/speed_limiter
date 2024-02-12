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
    # @option params [true, Hash] :retry Retry options. (see {Retryable.retryable} for details)
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
      if use_retryable?
        Retryable.retryable(**retryable_options) { run_block(&block) }
      else
        run_block(&block)
      end
    end

    private

    def use_retryable?
      return false if params.retry == false || params.retry.nil?

      unless Gem::Specification.find_by_name("retryable")
        raise ArgumentError, "To use the 'retry' option, you need to install the Retryable gem."
      end

      require "retryable"
      params.retry.is_a?(Hash) || params.retry == true
    end

    def retryable_options
      return {} if params.retry == true

      params.retry
    end

    def run_block(&block)
      return block.call(create_state) if config.no_limit?

      loop do
        count, ttl = redis.increment(redis_key, period)

        break(block.call(create_state(count: count, ttl: ttl))) if count <= limit

        wait_for_interval(count)
      end
    end

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
