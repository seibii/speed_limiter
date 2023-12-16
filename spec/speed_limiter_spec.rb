# frozen_string_literal: true

require "spec_helper"
require "net/http"
require "uri"
require "securerandom"
require "benchmark"
require "parallel"

RSpec.describe SpeedLimiter do
  describe ".throttle" do
    let!(:throttle_server) { URI.parse(ENV.fetch("TEST_THROTTLE_SERVER", "http://localhost:9292")) }
    let!(:http) { Net::HTTP.new(throttle_server.host, throttle_server.port) }

    before do
      redis_url = ENV.fetch("TEST_REDIS_URL", "redis://localhost:6379/0")
      described_class.configure do |config|
        config.redis_url = redis_url
      end
    end

    it "return the block return value" do
      expect(described_class.throttle("block return value", limit: 1, period: 1) { "block return value" })
        .to eq("block return value")
    end

    it "block takes count as arguments" do
      expect { |b| described_class.throttle("block arguments", limit: 10, period: 1, &b) }.to yield_with_args(1)
      expect { |b| described_class.throttle("block arguments", limit: 10, period: 1, &b) }.to yield_with_args(2)
      expect { |b| described_class.throttle("block arguments", limit: 10, period: 1, &b) }.to yield_with_args(3)
    end

    context "when the server can only be accessed 10 times per second" do
      it "completes 11 accesses within 1.1 seconds without being caught by the limiter" do
        path = "/10/1s?#{Random.uuid}"

        time = Benchmark.realtime do
          11.times do
            described_class.throttle(path, limit: 10, period: 1) do
              response = http.get(path)
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

        time = Benchmark.realtime do
          Parallel.map(1..101, in_processes: 5) do
            described_class.throttle(path, limit: 100, period: 1) do
              response = http.get(path)
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

        time = Benchmark.realtime do
          Parallel.map(1..101, in_processes: 5) do
            described_class.throttle(path, limit: 9, period: 1) do
              response = http.get(path)
              expect(response).to be_a(Net::HTTPOK)
            end
          end
        end

        puts "    run time: #{time}seconds"
        expect(time).to be < 12
      end
    end

    context "when 'on_throttled' is specified as an argument" do
      it "when the limit is reached, 'on_throttled' is called" do
        on_throttled = proc { raise "limit exceeded" }
        allow(on_throttled).to receive(:call).and_call_original

        expect do |b|
          2.times do
            described_class.throttle("on_throttled", limit: 1, period: 1, on_throttled: on_throttled, &b)
          end
        end.to raise_error("limit exceeded").and(yield_control.once)

        expect(on_throttled).to have_received(:call).with(0.9..1, "speed_limiter:on_throttled").once
      end
    end

    context "when a proc is set in 'config.on_throttled'" do
      around do |example|
        described_class.configure do |config|
          config.on_throttled = proc { |ttl, key| raise "limit exceeded #{key} #{ttl}" }
        end

        example.run

        described_class.configure do |config|
          config.on_throttled = nil
        end
      end

      it "when the limit is reached, 'config.on_throttled' is called" do
        block_mock = proc { "block return value" }
        allow(block_mock).to receive(:call).and_call_original

        expect do
          2.times do
            described_class.throttle("config.on_throttled", limit: 1, period: 1) do
              block_mock.call
            end
          end
        end.to raise_error(/limit exceeded speed_limiter:config.on_throttled 0.9\d+/)

        expect(block_mock).to have_received(:call).once
      end
    end
  end
end
