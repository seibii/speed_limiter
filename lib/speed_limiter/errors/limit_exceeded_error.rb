# frozen_string_literal: true

require "forwardable"

module SpeedLimiter
  module Errors
    # SpeedLimiter limit exceeded Base Error
    class LimitExceededError < StandardError
      extend Forwardable

      # @param state [SpeedLimiter::State]
      def initialize(state)
        @state = state
        super(error_message)
      end
      attr_reader :state

      # @!method key
      #   @see SpeedLimiter::State#key
      # @!method ttl
      #   @see SpeedLimiter::State#ttl
      # @!method count
      #   @see SpeedLimiter::State#count
      # @!method limit
      #   @see SpeedLimiter::State#limit
      # @!method period
      #   @see SpeedLimiter::State#period
      delegate %i[key ttl count limit period] => :@state

      def error_message
        "#{key} rate limit exceeded. Retry after #{ttl} seconds. limit=#{limit}, count=#{count}, period=#{period}"
      end
    end
  end
end
