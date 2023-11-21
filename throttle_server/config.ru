# frozen_string_literal: true

require "rack/attack"
use Rack::Attack

# Throttling test server
module ThrottlingServer
  THROTTLE_MATCHER = %r{/(\d+)/(\d+)s(\?.+=.*)?}

  def self.call(env)
    case env["REQUEST_URI"]
    when "/"
      [200, { "content-type" => "text/plain" }, ["Hi!\nPlease access to /#\{limit}/#\{period}s\n\n", throttle_info]]
    when THROTTLE_MATCHER
      (limit, period) = Regexp.last_match.captures

      puts "[OK] #{env['REQUEST_METHOD']} #{env['REQUEST_URI']}\n  #{throttle_info.gsub("\n", "\n  ")}"
      [200, { "content-type" => "text/plain" }, ["OK\n#{limit} / #{period} seconds\n\n", throttle_info]]
    else
      [404, { "content-type" => "text/plain" }, ["Not Found"]]
    end
  end

  def self.throttle_info
    list = REDIS.scan_each.map { |key| "#{key} count: #{REDIS.get(key)}, ttl: #{REDIS.pttl(key)}ms" }.sort.join("\n")
    "Throttle Info:\n#{list}"
  end

  def self.limit(req)
    case req.path
    when THROTTLE_MATCHER
      Regexp.last_match.captures[0].to_i
    else
      9999
    end
  end

  def self.period(req)
    case req.path
    when THROTTLE_MATCHER
      Regexp.last_match.captures[1].to_i
    else
      9999
    end
  end
end

Rack::Attack.throttle(
  "requests by path", limit: ThrottlingServer.method(:limit),
                      period: ThrottlingServer.method(:period)
) do |request|
  request.url if request.url.match(ThrottlingServer::THROTTLE_MATCHER)
end

Rack::Attack.throttled_responder = lambda do |env|
  puts "[Retry later] #{env['REQUEST_METHOD']} #{env['REQUEST_URI']}\n  " \
       "#{ThrottlingServer.throttle_info.gsub("\n", "\n  ")}"
  [429, {}, ["Retry later\n\n", ThrottlingServer.throttle_info]]
end

require "redis"
REDIS = Rack::Attack.cache.store = Redis.new(url: ENV.fetch("THROTTLE_SERVER_REDIS_URL", "redis://localhost:6379/15"))

run ThrottlingServer
