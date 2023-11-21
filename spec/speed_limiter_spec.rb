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
  end
end
