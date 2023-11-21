# frozen_string_literal: true

workers 5

stdout_redirect "throttle_server/tmp/puma_stdout.log", "throttle_server/tmp/puma_stderr.log", true
pidfile "throttle_server/tmp/puma.pid"

preload_app!
