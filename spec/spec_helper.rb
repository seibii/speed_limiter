# frozen_string_literal: true

require "speed_limiter"
require "rspec"
require "net/http"
require "uri"

# Environment Check
redis_url = ENV.fetch("TEST_REDIS_URL", "redis://localhost:6379/0")
begin
  Redis.new(url: redis_url).ping
rescue Redis::CannotConnectError
  puts "Redis connection error:\n  Please run `docker compose up -d redis`"
  exit 1
end

throttle_server = URI.parse(ENV.fetch("TEST_THROTTLE_SERVER", "http://localhost:9292"))
begin
  Net::HTTP.get(throttle_server)
rescue Errno::ECONNREFUSED
  puts "Throttle Server connection error:\n  Please run `rake throttle_server:start_daemon`"
  exit 1
end

shared_context "initialize" do # rubocop:disable RSpec/ContextWording
  let!(:throttle_server) do # rubocop:disable RSpec/LetSetup
    Net::HTTP.new(throttle_server.host, throttle_server.port)
  end

  before do
    SpeedLimiter.configure do |config|
      config.redis_url = redis_url
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.include_context "initialize"
end
