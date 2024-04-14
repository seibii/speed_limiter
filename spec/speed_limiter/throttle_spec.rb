# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "benchmark"
require "parallel"

RSpec.describe SpeedLimiter::Throttle do
  let!(:config) { SpeedLimiter::Config.new }

  describe "#call" do
    it "block takes SpeedLimiter::State as arguments" do
      throttle = described_class.new(Random.uuid, config: config, limit: 10, period: 1)

      expect { |b| throttle.call(&b) }.to yield_with_args(
        be_a(SpeedLimiter::State).and(have_attributes(count: 1, ttl: -1..1, limit: 10, period: 1))
      )
      expect { |b| throttle.call(&b) }.to yield_with_args(
        be_a(SpeedLimiter::State).and(have_attributes(count: 2, ttl: -1..1, limit: 10, period: 1))
      )
      expect { |b| throttle.call(&b) }.to yield_with_args(
        be_a(SpeedLimiter::State).and(have_attributes(count: 3, ttl: -1..1, limit: 10, period: 1))
      )
    end

    context "when the server can only be accessed 10 times per second" do
      it "completes 11 accesses within 1.1 seconds without being caught by the limiter" do
        path = "/10/1s?#{Random.uuid}"
        throttle = described_class.new(path, config: config, limit: 10, period: 1)

        time = Benchmark.realtime do
          11.times do
            throttle.call do
              response = throttle_server.get(path)
              expect(response).to be_a(Net::HTTPOK)
            end
          end
        end

        puts "    run time: #{time}seconds"
        expect(time).to be_within(0.1).of(1.0)
      end
    end

    context "when accessing with 5 threads and the server can only be accessed 100 times per 1 second" do
      it "completes 101 accesses within 1.1 seconds without being caught by the limiter" do
        path = "/100/1s?#{Random.uuid}"
        throttle = described_class.new(path, config: config, limit: 100, period: 1)

        time = Benchmark.realtime do
          Parallel.map(1..101, in_processes: 5) do
            throttle.call do
              response = throttle_server.get(path)
              expect(response).to be_a(Net::HTTPOK)
            end
          end
        end

        puts "    run time: #{time}seconds"
        expect(time).to be_within(0.1).of(1.0)
      end
    end

    context "when accessing with 5 threads and the server can only be accessed 10 times per 1 second" do
      it "completes 101 accesses within 12 seconds without being caught by the limiter" do
        path = "/10/1s?#{Random.uuid}"
        throttle = described_class.new(path, config: config, limit: 9, period: 1)

        time = Benchmark.realtime do
          Parallel.map(1..101, in_processes: 5) do
            throttle.call do
              response = throttle_server.get(path)
              expect(response).to be_a(Net::HTTPOK)
            end
          end
        end

        puts "    run time: #{time}seconds"
        expect(time).to be < 12
      end
    end

    context "when 'raise_on_throttled: true' is specified as an argument" do
      it "raises an exception when the limit is reached" do
        throttle = described_class.new(Random.uuid, config: config, limit: 1, period: 1, raise_on_throttled: true)

        expect { 2.times { throttle.call { nil } } }.to raise_error(SpeedLimiter::Errors::ThrottledError) do |error|
          expect(error).to have_attributes(key: be_a(String), ttl: 0.9..1, count: 2)
        end
      end
    end

    context "when 'raise_on_throttled: SpeedLimiter::Errors::LimitExceededError' is specified as an argument" do
      it "raises a SpeedLimiter::Errors::LimitExceededError exception when the limit is reached" do
        throttle = described_class.new(
          Random.uuid, config: config, limit: 1, period: 1, raise_on_throttled: SpeedLimiter::Errors::LimitExceededError
        )

        expect { 2.times { throttle.call { nil } } }.to raise_error(SpeedLimiter::Errors::LimitExceededError) do |error|
          expect(error).to have_attributes(key: be_a(String), ttl: 0.9..1, count: 2)
        end
      end
    end

    context "when 'on_throttled' is specified as an argument" do
      it "when the limit is reached, 'on_throttled' is called" do
        on_throttled = proc { raise "limit exceeded" }
        allow(on_throttled).to receive(:call).and_call_original

        throttle = described_class.new(Random.uuid, config: config, limit: 1, period: 1, on_throttled: on_throttled)

        expect do |b|
          2.times { throttle.call(&b) }
        end.to raise_error("limit exceeded").and(yield_control.once)

        expect(on_throttled).to have_received(:call)
          .with(be_a(SpeedLimiter::State).and(have_attributes(count: 2, ttl: 0.9..1))).once
      end
    end

    context "when a proc is set in 'config.on_throttled'" do
      let!(:config) do
        SpeedLimiter::Config.new.tap do |config|
          config.on_throttled = proc { |state| raise "limit exceeded #{state.key} #{state.ttl} #{state.count}" }
        end
      end

      it "when the limit is reached, 'config.on_throttled' is called" do
        block_mock = proc { "block return value" }
        allow(block_mock).to receive(:call).and_call_original

        key = Random.uuid
        throttle = described_class.new(key, config: config, limit: 1, period: 1)

        expect do
          2.times do
            throttle.call { block_mock.call }
          end
        end.to raise_error(/limit exceeded #{key} (0\.9\d+|1\.0) 2/)

        expect(block_mock).to have_received(:call).once
      end
    end

    context "when StandardError for retry option" do
      it do
        block_mock = proc { "block return value" }
        allow(block_mock).to receive(:call).and_raise(StandardError)

        key = Random.uuid
        throttle = described_class.new(key, config: config, limit: 1, period: 1, retry: { on: StandardError, tries: 2 })

        expect { throttle.call { block_mock.call } }.to raise_error(StandardError)
        expect(block_mock).to have_received(:call).twice
      end
    end
  end
end
