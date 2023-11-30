[![lint](https://github.com/seibii/speed_limiter/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/seibii/speed_limiter/actions/workflows/lint.yml) [![test](https://github.com/seibii/speed_limiter/actions/workflows/test.yml/badge.svg)](https://github.com/seibii/speed_limiter/actions/workflows/test.yml) [![Gem Version](https://badge.fury.io/rb/speed_limiter.svg)](https://badge.fury.io/rb/speed_limiter) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

# SpeedLimiter

<img src="README_image.jpg" width="400px" />

This is a Gem for execution limits in multi-process and multi-threaded environments. By using Redis, you can limit execution across multiple processes and threads.

It was mainly created to avoid hitting access limits to the API server.

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

```ruby
# Limit the number of executions to 10 times per second
SpeedLimiter.throttle('server_name/method_name', limit: 10, period: 1) do
  # Do something
end
```

### Configuration

```ruby
# config/initializers/speed_limiter.rb
SpeedLimiter.configure do |config|
  config.redis_url = ENV['SPEED_LIMITER_REDIS_URL'] || 'redis://localhost:6379/2'
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
