# frozen_string_literal: true

require "speed_limiter/state"
require "forwardable"

module SpeedLimiter
  # Execution status model
  class State
    extend Forwardable

    # @param params [SpeedLimiter::ThrottleParams]
    # @param count [Integer] current count
    # @param ttl [Float] remaining time to reset
    def initialize(params:, count:, ttl:)
      @params = params
      @count = count
      @ttl = ttl
    end

    attr_reader :params, :count, :ttl

    def_delegators(:params, :config, :key, :limit, :period, :on_throttled, :retry)

    def inspect
      "<#{self.class.name} key=#{key.inspect} count=#{count} ttl=#{ttl}>"
    end
    alias to_s inspect
  end
end
