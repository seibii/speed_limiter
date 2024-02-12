# frozen_string_literal: true

require "spec_helper"

RSpec.describe SpeedLimiter do
  describe ".throttle" do
    context "when block arguments is included" do
      it "return the block return value" do
        expect(described_class.throttle("block return value", limit: 1, period: 1) { "block return value" })
          .to eq("block return value")
      end

      it "block takes SpeedLimiter::State as arguments" do
        expect { |b| described_class.throttle("block arguments", limit: 10, period: 1, &b) }.to yield_with_args(
          be_a(SpeedLimiter::State).and(have_attributes(count: 1, ttl: -1..1, limit: 10, period: 1))
        )
      end
    end

    context "when bloc arguments is not included" do
      it "return Throttle instance" do
        expect(described_class.throttle("return Throttle instance", limit: 1, period: 1))
          .to be_a(SpeedLimiter::Throttle)
      end

      it "block takes SpeedLimiter::State as arguments" do
        throttle = described_class.throttle("not block arguments", limit: 10, period: 1)
        expect { |b| throttle.call(&b) }.to yield_with_args(
          be_a(SpeedLimiter::State).and(have_attributes(count: 1, ttl: -1..1, limit: 10, period: 1))
        )
      end
    end
  end
end
