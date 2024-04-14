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
    # @option params [true, Class] :raise_on_throttled
    #   Raise error when limit exceeded. If Class is given, it will be raised instead of SpeedLimiter::ThrottledError.
    #   If you want to specify a custom error class, please specify a class that inherits from
    #   SpeedLimiter::LimitExceededError or a class that accepts SpeedLimiter::State as an argument.
    # @option params [true, Hash] :retry Retry options. (see {Retryable.retryable} for details)
    def initialize(key, config:, **params)
      params[:key] = key.to_s

      @config = config
      @params = ThrottleParams.new(config: config, **params)
    end
    attr_reader :config, :params, :block

    delegate %i[redis_client] => :@config

    delegate %i[
      key redis_key limit period on_throttled raise_on_throttled_class raise_on_throttled? create_state
    ] => :@params

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
        count, ttl = redis_client.increment(redis_key, period)

        break(block.call(create_state(count: count, ttl: ttl))) if count <= limit

        wait_for_interval(count)
      end
    end

    def wait_for_interval(count)
      ttl = redis_client.ttl(redis_key)
      return if ttl.negative?

      create_state(count: count, ttl: ttl).tap do |state|
        raise raise_on_throttled_class, state if raise_on_throttled?

        config.on_throttled.call(state) if config.on_throttled.respond_to?(:call)
        on_throttled.call(state) if on_throttled.respond_to?(:call)
      end

      ttl = redis_client.ttl(redis_key)
      return if ttl.negative?

      sleep ttl
    end
  end
end
