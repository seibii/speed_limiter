[![lint](https://github.com/seibii/speed_limiter/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/seibii/speed_limiter/actions/workflows/lint.yml) [![test](https://github.com/seibii/speed_limiter/actions/workflows/test.yml/badge.svg)](https://github.com/seibii/speed_limiter/actions/workflows/test.yml) [![Gem Version](https://badge.fury.io/rb/speed_limiter.svg)](https://badge.fury.io/rb/speed_limiter) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

# SpeedLimiter

<img src="README_image.jpg" width="400px" />

SpeedLimiter is a gem that limits the number of executions per unit of time.
By default, it achieves throttling through sleep.

You can also use the `on_throttled` event to raise an exception instead of sleeping, or to re-enqueue the task.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'speed_limiter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install speed_limiter

## Usage

Limit the number of executions to 10 times per second.

```ruby
SpeedLimiter.throttle('server_name/method_name', limit: 10, period: 1) do |count|
  logger.info("throttle #{count}/10/sec")
  http.get(path)
end
```

It returns the result of the block execution.

```ruby
result = SpeedLimiter.throttle('server_name/method_name', limit: 10, period: 1) do
  http.get(path)
end
puts result.body
```

Specify the process when the limit is exceeded.

```ruby
on_throttled = proc { |ttl, key| logger.info("limit exceeded #{key} #{ttl}") }
SpeedLimiter.throttle('server_name/method_name', limit: 10, period: 1, on_throttled: on_throttled) do
  http.get(path)
end
```

Reinitialize the queue instead of sleeping when the limit is reached in ActiveJob.

```ruby
class CreateSlackChannelJob < ApplicationJob
  def perform(*args)
    on_throttled = proc do |ttl, _key|
      raise Slack::LimitExceeded, ttl if ttl > 5
    end

    SpeedLimiter.throttle("slack", limit: 20, period: 1.minute, on_throttled: on_throttled) do
      create_slack_channel(*args)
    end
  rescue Slack::LimitExceeded => e
    self.class.set(wait: e.ttl).perform_later(*args)
  end
end
```

### Configuration

```ruby
# config/initializers/speed_limiter.rb
SpeedLimiter.configure do |config|
  config.redis_url = ENV.fetch('SPEED_LIMITER_REDIS_URL', 'redis://localhost:6379/2')
end
```

or Use Redis instance

```ruby
# config/initializers/speed_limiter.rb
SpeedLimiter.configure do |config|
  config.redis = Redis.new(host: 'localhost', port: 6379, db: 2)
end
```

If you do not want to impose a limit in the test environment, please set it as follows.

```ruby
# spec/support/speed_limiter.rb
RSpec.configure do |config|
  config.before(:suite) do
    SpeedLimiter.configure do |config|
      config.no_limit = true
    end
  end
end
```

If you want to detect the limit in the test environment, please set it as follows.

```ruby
Rspec.describe do
  around do |example|
    SpeedLimiter.config.on_throttled = proc { |ttl, key| raise "limit exceeded #{key} #{ttl}" }

    example.run

    SpeedLimiter.config.on_throttled = nil
  end

  it do
    expect { over_limit_method }.to raise_error('limit exceeded speed_limiter:key_name [\d.]+')
  end
end
```

## Compatibility

SpeedLimiter officially supports the following Ruby implementations and Redis :

- Ruby MRI 3.0, 3.1, 3.2
- Redis 5.0, 6.0, 6.2, 7.0, 7.2


## Development

After checking out the repo, run `bin/setup` to install dependencies.
Please run rspec referring to the following.

Before committing, run bundle exec rubocop to perform a style check.
You can also run bin/console for an interactive prompt that will allow you to experiment.

### rspec

Start a web server and Redis for testing with the following command.

```
$ rake test:throttle_server
$ docker compose up
```

After that, please run the test with the following command.

```
$ bundle exec rspec -fd
```

## Contribution

1. Fork it ( https://github.com/seibii/speed_limiter/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
