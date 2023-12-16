# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "benchmark"
require "parallel"

RSpec.describe SpeedLimiter::State do
  let(:config) { SpeedLimiter::Config.new }
  let(:params) do
    SpeedLimiter::ThrottleParams.new(
      config: config,
      key: "test_key",
      limit: 10,
      period: 60,
      on_throttled: nil
    )
  end

  describe "#inspect" do
    it do
      expect(described_class.new(params: params, count: 1, ttl: 2).inspect)
        .to eq("<SpeedLimiter::State key=\"test_key\" count=1 ttl=2>")
    end
  end

  describe "#to_s" do
    it do
      expect(described_class.new(params: params, count: 1, ttl: 2).to_s)
        .to eq("<SpeedLimiter::State key=\"test_key\" count=1 ttl=2>")
    end
  end
end
