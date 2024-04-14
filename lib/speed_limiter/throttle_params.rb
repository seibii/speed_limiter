# frozen_string_literal: true

require "speed_limiter/state"

module SpeedLimiter
  # Throttle params model
  class ThrottleParams
    KNOWN_OPTIONS = %i[on_throttled retry].freeze

    # @param config [SpeedLimiter::Config]
    # @param key [String]
    # @param limit [Integer] limit count per period
    # @param period [Integer] period time (seconds)
    # @param options [Hash] options
    # @option options [Proc, #call] :on_throttled Block called when limit exceeded, with ttl(Float) and key as argument
    def initialize(config:, key:, limit:, period:, **options)
      @config = config
      @key = key
      @limit = limit
      @period = period
      @options = options

      return unless (unknown_options = options.keys - KNOWN_OPTIONS).any?

      raise ArgumentError, "Unknown options: #{unknown_options.join(', ')}"
    end

    # @!method config
    #   @return [SpeedLimiter::Config]
    # @!method key
    #   @return [String] Throttle key name
    # @!method limit
    #   @return [Integer] limit count per period
    # @!method period
    #   @return [Integer] period time (seconds)
    attr_reader :config, :key, :limit, :period

    def on_throttled
      @options[:on_throttled]
    end

    # @return [Boolean, Hash]
    def retry
      @options[:retry]
    end

    # @return [String]
    def redis_key
      "#{config.prefix}:#{key}"
    end

    # @param count [Integer, nil]
    # @param ttl [Float, nil]
    # @return [SpeedLimiter::State]
    def create_state(count: nil, ttl: nil)
      State.new(params: self, count: count, ttl: ttl)
    end
  end
end
