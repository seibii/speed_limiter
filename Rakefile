# frozen_string_literal: true

require "rubygems"
require "bundler/setup"

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: :spec

namespace :test do
  desc "Run rackup for throttle server daemon"
  task :throttle_server do
    system "puma -C throttle_server/puma.rb throttle_server/config.ru"
  end
end
