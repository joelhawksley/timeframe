# frozen_string_literal: true

# :nocov:
require "socket"
require "logger"
require "zlib"
require "fileutils"
require_relative "server" # reuse Packet class and constants

# Transparent TCP proxy between Visionect devices and a real VSS server.
# Logs and saves every byte in both directions without modification.
#
# Usage:
#   Set VISIONECT_PROXY_TARGET=192.168.1.91:11113 to enable proxy mode.
#   Devices connect to this proxy on VISIONECT_PORT (default 11114).
#   Proxy forwards all traffic to the VSS target and logs the exchange.
#
# Captures are saved to tmp/captures/<serial>_<timestamp>_device.bin
# and tmp/captures/<serial>_<timestamp>_server.bin

module VisionectProtocol
  class Proxy
    CAPTURE_DIR = File.expand_path("../../../../tmp/captures", __FILE__)
    CHUNK_SIZE = 65536

    def initialize(target_host:, target_port:, listen_port: 11114, logger: nil)
      @target_host = target_host
      @target_port = target_port
      @listen_port = listen_port
      @logger = logger || Logger.new($stdout, level: Logger::INFO)
      @running = false
      FileUtils.mkdir_p(CAPTURE_DIR)
    end

    def start
      @running = true
      @server = TCPServer.new("0.0.0.0", @listen_port)
      @logger.info "[Proxy] Listening on port #{@listen_port}, forwarding to #{@target_host}:#{@target_port}"

      while @running
        begin
          client = @server.accept
          Thread.new(client) { |c| handle_connection(c) }
        rescue IOError
          break unless @running
        end
      end
    rescue => e
      @logger.error "[Proxy] Server error: #{e.message}"
    ensure
      @server&.close
    end

    def stop
      @running = false
      @server&.close
    end

    private

    def handle_connection(device_sock)
      remote = "#{device_sock.peeraddr[2]}:#{device_sock.peeraddr[1]}"
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S_%L")
      @logger.info "[Proxy] Device connected from #{remote}"

      device_sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      # Connect to the real VSS server
      server_sock = TCPSocket.new(@target_host, @target_port)
      server_sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @logger.info "[Proxy] Connected to VSS at #{@target_host}:#{@target_port}"

      # Buffers for raw capture
      device_capture = String.new(encoding: "BINARY")
      server_capture = String.new(encoding: "BINARY")
      serial = nil
      packet_num = 0

      # Bidirectional relay using IO.select
      loop do
        ready = IO.select([device_sock, server_sock], nil, nil, 15)

        unless ready
          @logger.info "[Proxy] #{remote}: Timeout (15s idle), closing"
          break
        end

        ready[0].each do |sock|
          data = sock.recv(CHUNK_SIZE)

          if data.nil? || data.empty?
            @logger.info "[Proxy] #{remote}: #{(sock == device_sock) ? "Device" : "Server"} closed connection"
            raise StopIteration
          end

          if sock == device_sock
            # Device → Server
            device_capture << data
            server_sock.write(data)
            server_sock.flush

            direction = "DEVICE→SERVER"
            parsed = try_parse_packets(data)
            serial ||= extract_serial_from_data(data)
          else
            # Server → Device
            server_capture << data
            device_sock.write(data)
            device_sock.flush

            direction = "SERVER→DEVICE"
            parsed = try_parse_packets(data)
          end

          packet_num += 1
          log_data(direction, remote, packet_num, data, parsed)
        end
      end
    rescue StopIteration
      # Normal end of relay
    rescue => e
      @logger.error "[Proxy] #{remote}: #{e.class}: #{e.message}"
    ensure
      device_sock&.close
      server_sock&.close

      serial ||= "unknown"
      save_capture(serial, timestamp, "device", device_capture)
      save_capture(serial, timestamp, "server", server_capture)
      @logger.info "[Proxy] #{remote}: Session ended (serial=#{serial}, device=#{device_capture.bytesize}B, server=#{server_capture.bytesize}B)"
    end

    def try_parse_packets(data)
      return [] if data.bytesize < HEADER_SIZE

      packets = []
      offset = 0

      while offset + HEADER_SIZE <= data.bytesize
        version, flags, pkt_type, payload_len, checksum = data[offset, HEADER_SIZE].unpack("V5")

        total_len = HEADER_SIZE + payload_len
        break if offset + total_len > data.bytesize

        packets << {
          version: version,
          flags: flags,
          type: pkt_type,
          payload_len: payload_len,
          checksum: format("0x%08X", checksum),
          offset: offset,
          total_len: total_len
        }

        offset += total_len
      end

      packets
    end

    def extract_serial_from_data(data)
      return nil if data.bytesize < HEADER_SIZE + SUB_HEADER_SIZE + 12

      # Try to parse as a packet and extract serial
      pkt = Packet.new(payload: data[HEADER_SIZE..])
      pkt.extract_serial
    rescue
      nil
    end

    def log_data(direction, remote, packet_num, data, parsed)
      @logger.info "[Proxy] #{remote} ##{packet_num} #{direction} (#{data.bytesize} bytes)"

      parsed.each_with_index do |pkt, i|
        @logger.info "  Packet #{i}: ver=#{pkt[:version]} flags=#{pkt[:flags]} type=#{pkt[:type]} " \
          "payload=#{pkt[:payload_len]}B checksum=#{pkt[:checksum]}"
      end

      # Hex dump (first 256 bytes max per transfer)
      hex_bytes = [data.bytesize, 256].min
      hex_lines = data[0, hex_bytes].bytes.each_slice(16).map.with_index do |row, i|
        hex = row.map { |b| format("%02X", b) }.join(" ")
        ascii = row.map { |b| (b >= 0x20 && b < 0x7F) ? b.chr : "." }.join
        format("  %04X: %-48s  %s", i * 16, hex, ascii)
      end
      hex_lines.each { |line| @logger.info line }

      if data.bytesize > 256
        @logger.info "  ... (#{data.bytesize - 256} more bytes)"
      end
    end

    def save_capture(serial, timestamp, direction, data)
      return if data.empty?

      filename = "#{serial}_#{timestamp}_#{direction}.bin"
      path = File.join(CAPTURE_DIR, filename)
      File.binwrite(path, data)
      @logger.info "[Proxy] Saved #{path} (#{data.bytesize} bytes)"
    end
  end
end
# :nocov:
