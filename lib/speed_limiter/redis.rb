# frozen_string_literal: true

module SpeedLimiter
  # Redis wrapper
  class Redis
    def initialize(redis)
      @redis = redis
    end
    attr_reader :redis

    def ttl(key)
      redis.pttl(key) / 1000.0
    end

    def increment(key, period) # rubocop:disable Metrics/MethodLength
      if supports_expire_nx?
        count, ttl = redis.pipelined do |pipeline|
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

      [count, ttl]
    end

    private

    def supports_expire_nx?
      return @supports_expire_nx if defined?(@supports_expire_nx)

      redis_versions = redis.info("server")["redis_version"]
      @supports_expire_nx = Gem::Version.new(redis_versions) >= Gem::Version.new("7.0.0")
    end
  end
end
