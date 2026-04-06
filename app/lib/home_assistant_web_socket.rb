# frozen_string_literal: true

require "websocket-client-simple"
require "json"

class HomeAssistantWebSocket
  RECONNECT_BASE_DELAY = 1
  RECONNECT_MAX_DELAY = 60

  def initialize(config = TimeframeConfig.new, store: Rails.cache)
    @config = config
    @store = store
    @running = false
    @reconnect_delay = RECONNECT_BASE_DELAY
    @message_id = 0
    @mutex = Mutex.new
  end

  def start
    @running = true

    while @running
      begin
        connect_and_listen
      rescue => e
        Rails.logger.error "[HA WebSocket] Connection error: #{e.message}"
      end

      if @running
        Rails.logger.info "[HA WebSocket] Reconnecting in #{@reconnect_delay}s..."
        sleep @reconnect_delay
        @reconnect_delay = [@reconnect_delay * 2, RECONNECT_MAX_DELAY].min
      end
    end
  end

  def stop
    @running = false
    @ws&.close
  end

  private

  def next_id
    @mutex.synchronize { @message_id += 1 }
  end

  def websocket_url
    base = @config.home_assistant_url
    ws_url = base.sub(/^http/, "ws")
    "#{ws_url}/api/websocket"
  end

  def connect_and_listen
    ready = Queue.new
    handler = self
    url = websocket_url

    @ws = WebSocket::Client::Simple.connect(url)
    ws = @ws

    ws.on :message do |msg|
      handler.send(:handle_message, JSON.parse(msg.data))
    rescue => e
      Rails.logger.error "[HA WebSocket] Message error: #{e.message}"
    end

    ws.on :open do
      Rails.logger.info "[HA WebSocket] Connected to #{url}"
    end

    ws.on :close do
      Rails.logger.info "[HA WebSocket] Connection closed"
      ready.push(:closed)
    end

    ws.on :error do |e|
      Rails.logger.error "[HA WebSocket] Error: #{e.message}"
    end

    # Block until connection closes
    ready.pop
  end

  def handle_message(data)
    case data["type"]
    when "auth_required"
      send_message(type: "auth", access_token: @config.home_assistant_token)

    when "auth_ok"
      Rails.logger.info "[HA WebSocket] Authenticated"
      @reconnect_delay = RECONNECT_BASE_DELAY

      # Fetch full initial state via HTTP, then subscribe to changes
      begin
        HomeAssistantApi.new(@config, store: @store).fetch_states
        DisplayBroadcaster.broadcast_all_mira_displays
      rescue => e
        Rails.logger.error "[HA WebSocket] Initial state fetch failed: #{e.message}"
      end

      send_message(id: next_id, type: "subscribe_events", event_type: "state_changed")
      Rails.logger.info "[HA WebSocket] Subscribed to state_changed events"

    when "auth_invalid"
      Rails.logger.error "[HA WebSocket] Authentication failed: #{data["message"]}"
      @running = false

    when "event"
      handle_state_changed(data["event"]) if data.dig("event", "event_type") == "state_changed"

    when "result"
      # Subscription confirmation, ignore
    end
  end

  def handle_state_changed(event)
    new_state = event.dig("data", "new_state")
    return unless new_state

    entity_id = new_state["entity_id"]

    # Update the cached states array with the new entity state
    api = HomeAssistantApi.new(@config, store: @store)
    api.update_entity_state(entity_id, new_state)

    begin
      DisplayBroadcaster.broadcast_all_mira_displays
    rescue => e
      Rails.logger.error "[HA WebSocket] Broadcast failed: #{e.message}"
    end
  end

  def send_message(data)
    @ws&.send(data.to_json)
  end
end
