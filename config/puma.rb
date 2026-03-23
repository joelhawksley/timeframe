# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = 2
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV", "development")

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
plugin :"rufus-scheduler"

# Start Visionect TCP server alongside Puma (works in both single and cluster mode)
on_booted do
  start_visionect_server
end

def start_visionect_server
  return if @visionect_started

  require_relative "../app/lib/visionect_protocol/server"
  visionect_port = ENV.fetch("VISIONECT_PORT", 11113).to_i

  @visionect_server = VisionectProtocol::Server.new(
    port: visionect_port,
    logger: Logger.new($stdout, level: Logger::INFO)
  )

  @visionect_thread = Thread.new do
    @visionect_server.start
  rescue => e
    warn "[Visionect] Server thread error: #{e.message}"
  end

  @visionect_started = true
end

before_restart do
  @visionect_server&.stop
end
