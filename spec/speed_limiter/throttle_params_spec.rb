# frozen_string_literal: true

require "spec_helper"

RSpec.describe SpeedLimiter::Throttle do
  let!(:config) { SpeedLimiter::Config.new }

  describe "#new" do
    context "with unknown options" do
      it "raises ArgumentError" do
        expect { described_class.new(config: config, key: SecureRandom.uuid, limit: 1, period: 1, unknown: true) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
