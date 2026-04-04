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

# Start Visionect TCP server or proxy alongside Puma.
#
# Proxy mode: set VISIONECT_PROXY_TARGET to forward device traffic to a real
# VSS server while logging every byte. Example:
#   VISIONECT_PROXY_TARGET=192.168.1.91:11113
#
# Normal mode: runs the custom protocol server (when VISIONECT_PROXY_TARGET is unset).
after_booted do
  start_visionect_server
end

def start_visionect_server
  return if @visionect_started

  visionect_port = ENV.fetch("VISIONECT_PORT", 11114).to_i
  proxy_target = ENV["VISIONECT_PROXY_TARGET"]

  if proxy_target
    require_relative "../app/lib/visionect_protocol/proxy"
    host, port = proxy_target.split(":")
    port = (port || 11113).to_i

    @visionect_server = VisionectProtocol::Proxy.new(
      target_host: host,
      target_port: port,
      listen_port: visionect_port,
      logger: Logger.new($stdout, level: Logger::INFO)
    )
  else
    require_relative "../app/lib/visionect_protocol/server"

    @visionect_server = VisionectProtocol::Server.new(
      port: visionect_port,
      logger: Logger.new($stdout, level: Logger::INFO)
    )
  end

  @visionect_thread = Thread.new do
    @visionect_server.start
  rescue => e
    warn "[Visionect] Server/proxy thread error: #{e.message}"
  end

  @visionect_started = true
end

before_restart do
  @visionect_server&.stop
end
