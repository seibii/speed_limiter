# frozen_string_literal: true

require "speed_limiter/version"
require "speed_limiter/config"
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

    def redis
      @redis ||= config.redis || Redis.new(url: config.redis_url)
    end

    def throttle(key, limit:, period:, &block)
      return block&.call if config.no_limit?

      key_name = "#{config.prefix}:#{key}"
      loop do
        count = increment(key_name, period)

        break(block&.call) if count <= limit

        wait_for_interval(key_name)
      end
    end

    private

    def wait_for_interval(key)
      pttl = redis.pttl(key)
      ttl = pttl / 1000.0

      return if ttl.negative?

      sleep ttl
    end

    def increment(key, period) # rubocop:disable Metrics/MethodLength
      if supports_expire_nx?
        count, = redis.pipelined do |pipeline|
          pipeline.incrby(key, 1)
          pipeline.call(:expire, key, period.to_i, "NX")
        end
      else
        count, ttl = redis.pipelined do |pipeline|
          pipeline.incrby(key, 1)
          pipeline.ttl(key)
        end
        redis.expire(key, period.to_i) if ttl.negative?
      end

      count
    end

    def supports_expire_nx?
      return @supports_expire_nx if defined?(@supports_expire_nx)

      redis_versions = redis.info("server")["redis_version"]
      @supports_expire_nx = Gem::Version.new(redis_versions) >= Gem::Version.new("7.0.0")
    end
  end
end
