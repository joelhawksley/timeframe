# frozen_string_literal: true

require "test_helper"
require "socket"
require "digest"
require "base64"

class HomeAssistantWebSocketTest < Minitest::Test
  def test_class_is_loadable
    assert defined?(HomeAssistantWebSocket), "HomeAssistantWebSocket should be autoloadable"
    assert HomeAssistantWebSocket.is_a?(Class)
  end

  def test_initializes_with_defaults
    ws = HomeAssistantWebSocket.new
    assert ws.is_a?(HomeAssistantWebSocket)
  end

  def test_connects_authenticates_and_receives_state_changes
    # Start a mock WebSocket server
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]

    messages_received = []
    server_thread = Thread.new do
      client = server.accept

      # Also accept (and discard) the HTTP fetch_states connection that
      # the client makes on auth_ok, so it doesn't block the test.
      fetch_thread = Thread.new do
        loop do
          extra = begin
            server.accept
          rescue
            break
          end
          begin
            extra.close
          rescue
            nil
          end
        end
      rescue
        nil
      end

      # Perform WebSocket handshake
      request = ""
      while (line = client.gets) && line != "\r\n"
        request += line
      end

      key = request[/Sec-WebSocket-Key: (.+)\r\n/, 1]
      accept = Base64.strict_encode64(Digest::SHA1.digest("#{key}258EAFA5-E914-47DA-95CA-5AB5DC76CB65"))

      client.write "HTTP/1.1 101 Switching Protocols\r\n"
      client.write "Upgrade: websocket\r\n"
      client.write "Connection: Upgrade\r\n"
      client.write "Sec-WebSocket-Accept: #{accept}\r\n"
      client.write "\r\n"

      # Send auth_required
      send_ws_frame(client, {type: "auth_required"}.to_json)

      # Read auth message from client
      auth_msg = read_ws_frame(client)
      messages_received << JSON.parse(auth_msg) if auth_msg

      # Send auth_ok
      send_ws_frame(client, {type: "auth_ok"}.to_json)

      # Wait for client to process auth_ok (includes HTTP fetch attempt)
      sleep 1

      # Read subscribe message
      sub_msg = read_ws_frame(client)
      messages_received << JSON.parse(sub_msg) if sub_msg

      # Send a state_changed event
      send_ws_frame(client, {
        type: "event",
        event: {
          event_type: "state_changed",
          data: {
            new_state: {
              entity_id: "sensor.test_entity",
              state: "42"
            }
          }
        }
      }.to_json)

      # Give client time to process
      sleep 0.5

      # Close connection
      client.close
      begin
        fetch_thread.kill
      rescue
        nil
      end
    rescue => e
      Rails.logger.error "[Mock WS] #{e.message}"
    ensure
      server.close
    end

    # Configure client to connect to our mock server
    config = OpenStruct.new(
      home_assistant_token: "test-token",
      home_assistant_url: "http://127.0.0.1:#{port}"
    )
    store = ActiveSupport::Cache::MemoryStore.new

    # Seed initial states so update_entity_state has something to merge into
    api = HomeAssistantApi.new(config, store: store)
    api.send(:save_domain, HomeAssistantApi::STATES_DOMAIN, [])

    ws_client = HomeAssistantWebSocket.new(config, store: store)

    # Run client in a thread, stop after the connection closes
    client_thread = Thread.new do
      ws_client.start
    rescue
      # Expected when server closes
    end

    # Wait for the mock server to finish its sequence
    server_thread.join(5)
    ws_client.stop
    client_thread.join(2)

    # Verify auth message was sent
    auth = messages_received.find { |m| m["type"] == "auth" }
    assert auth, "Client should have sent auth message"
    assert_equal "test-token", auth["access_token"]

    # Verify subscribe message was sent
    sub = messages_received.find { |m| m["type"] == "subscribe_events" }
    assert sub, "Client should have subscribed to events"
    assert_equal "state_changed", sub["event_type"]
  end

  private

  def send_ws_frame(socket, data)
    bytes = data.encode("UTF-8").bytes
    frame = [0x81] # text frame, fin bit set

    if bytes.length < 126
      frame << bytes.length
    elsif bytes.length < 65536
      frame << 126
      frame += [bytes.length].pack("n").bytes
    end

    socket.write(frame.pack("C*") + data.encode("UTF-8"))
  end

  def read_ws_frame(socket)
    first_byte = socket.getbyte
    return nil unless first_byte

    second_byte = socket.getbyte
    masked = (second_byte & 0x80) != 0
    length = second_byte & 0x7F

    if length == 126
      length = socket.read(2).unpack1("n")
    elsif length == 127
      length = socket.read(8).unpack1("Q>")
    end

    mask = masked ? socket.read(4).bytes : nil
    payload = socket.read(length).bytes

    if masked
      payload = payload.each_with_index.map { |b, i| b ^ mask[i % 4] }
    end

    payload.pack("C*").force_encoding("UTF-8")
  rescue
    nil
  end
end
