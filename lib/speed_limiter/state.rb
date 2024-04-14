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

    # @!method config
    #   @see SpeedLimiter::ThrottleParams#config
    # @!method key
    #   @see SpeedLimiter::ThrottleParams#key
    # @!method limit
    #   @see SpeedLimiter::ThrottleParams#limit
    # @!method period
    #   @see SpeedLimiter::ThrottleParams#period
    # @!method on_throttled
    #   @see SpeedLimiter::ThrottleParams#on_throttled
    # @!method retry
    #   @see SpeedLimiter::ThrottleParams#retry
    delegate %i[config key limit period on_throttled retry] => :@params

    def inspect
      "<#{self.class.name} key=#{key.inspect} count=#{count} ttl=#{ttl}>"
    end
    alias to_s inspect
  end
end
