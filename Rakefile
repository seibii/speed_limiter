# frozen_string_literal: true

require "rubygems"
require "bundler/setup"

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: :spec

namespace :throttle_server do
  desc "Run rackup for Throttle server"
  task :start do
    system "puma -C throttle_server/puma.rb throttle_server/config.ru"
  end

  desc "Run rackup for Throttle server daemon"
  task :start_daemon do
    system "pumad -C throttle_server/puma.rb throttle_server/config.ru"
  end

  desc "Stop the Throttle server daemon"
  task :stop do
    pid_file = "throttle_server/tmp/puma.pid"

    if File.exist?(pid_file)
      pid = File.read(pid_file).to_i
      begin
        Process.kill("TERM", pid)
        puts "Throttle server (PID: #{pid}) has been stopped."
      rescue Errno::ESRCH
        puts "Throttle server (PID: #{pid}) not found. It might have already stopped."
      rescue StandardError => e
        puts "Failed to stop Throttle server (PID: #{pid}): #{e.message}"
      end
    else
      puts "PID file not found. Is the Throttle server running?"
    end
  end
end
