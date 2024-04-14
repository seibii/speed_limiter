# frozen_string_literal: true

require "speed_limiter/state"

module SpeedLimiter
  # Throttle params model
  class ThrottleParams
    KNOWN_OPTIONS = %i[on_throttled retry].freeze

    def initialize(config:, key:, limit:, period:, **options)
      @config = config
      @key = key
      @limit = limit
      @period = period
      @options = options

      return unless (unknown_options = options.keys - KNOWN_OPTIONS).any?

      raise ArgumentError, "Unknown options: #{unknown_options.join(', ')}"
    end

    attr_reader :config, :key, :limit, :period

    def on_throttled
      @options[:on_throttled]
    end

    def retry
      @options[:retry]
    end

    def redis_key
      "#{config.prefix}:#{key}"
    end

    def create_state(count: nil, ttl: nil)
      State.new(params: self, count: count, ttl: ttl)
    end
  end
end
