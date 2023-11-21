# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "speed_limiter/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 3.0.0"

  spec.name          = "speed_limiter"
  spec.version       = SpeedLimiter::VERSION
  spec.authors       = ["yuhei mukoyama"]
  spec.email         = ["yuhei.mukoyama@seibii.com"]

  spec.summary       = "Limit the frequency of execution across multiple threads and processes"
  spec.homepage      = "https://github.com/seibii/speed_limiter"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["rubygems_mfa_required"] = "true"
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
          "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
end
