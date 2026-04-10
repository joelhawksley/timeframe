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
    @subscribed_entity_ids = []
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

  def refresh_entities!
    return unless @ws

    entity_ids = Rails.application.executor.wrap do
      HomeAssistantApi.new(@config, store: @store).watched_entity_ids
    end

    return if entity_ids.empty? || entity_ids.sort == @subscribed_entity_ids.sort

    Rails.logger.info "[HA WebSocket] Entity list changed (#{@subscribed_entity_ids.size} → #{entity_ids.size}), re-subscribing"

    # Unsubscribe current subscription
    if @subscribe_id
      send_message(id: next_id, type: "unsubscribe_events", subscription: @subscribe_id)
    end

    # Re-subscribe with updated list
    @entities = {}
    @subscribe_id = next_id
    @subscribed_entity_ids = entity_ids
    send_message(id: @subscribe_id, type: "subscribe_entities", entity_ids: entity_ids)
    Rails.logger.info "[HA WebSocket] Re-subscribed to #{entity_ids.size} entities"
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
    @entities = {}

    @ws = WebSocket::Client::Simple.connect(url)
    ws = @ws

    ws.on :message do |msg|
      next if msg.data.nil? || msg.data.empty?
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

      entity_ids = Rails.application.executor.wrap do
        HomeAssistantApi.new(@config, store: @store).watched_entity_ids
      end

      @subscribe_id = next_id
      @subscribed_entity_ids = entity_ids

      if entity_ids.any?
        send_message(id: @subscribe_id, type: "subscribe_entities", entity_ids: entity_ids)
        Rails.logger.info "[HA WebSocket] Subscribed to #{entity_ids.size} entities"
      else
        send_message(id: @subscribe_id, type: "subscribe_entities")
        Rails.logger.info "[HA WebSocket] Subscribed to all entities (no filter available)"
      end

    when "auth_invalid"
      Rails.logger.error "[HA WebSocket] Authentication failed: #{data["message"]}"
      @running = false

    when "event"
      handle_entity_event(data["event"]) if data["id"] == @subscribe_id

    when "result"
      # Subscription confirmation, ignore
    end
  end

  def handle_entity_event(event)
    changed = false

    # "a" = additions (initial dump or new entities) — full compressed state
    if (additions = event["a"])
      additions.each do |entity_id, compressed|
        @entities[entity_id] = expand_entity(entity_id, compressed)
      end
      changed = true
    end

    # "c" = changes — partial updates with "+" (added/changed) and "-" (removed) keys
    if (changes = event["c"])
      changes.each do |entity_id, diff|
        existing = @entities[entity_id]
        next unless existing

        apply_diff(existing, diff)
      end
      changed = true
    end

    # "r" = removals — array of entity IDs
    if (removals = event["r"])
      removals.each { |entity_id| @entities.delete(entity_id) }
      changed = true
    end

    return unless changed

    persist_states
    broadcast
  end

  # Convert compressed entity format to the full state format the app expects:
  #   s = state, a = attributes, c = context, lc = last_changed, lu = last_updated
  def expand_entity(entity_id, compressed)
    {
      "entity_id" => entity_id,
      "state" => compressed["s"],
      "attributes" => compressed["a"] || {},
      "last_changed" => compressed["lc"],
      "last_updated" => compressed["lu"],
      "context" => compressed["c"] || {}
    }
  end

  # Apply a diff to an existing expanded entity.
  # diff has "+" for added/changed fields and "-" for removed fields.
  def apply_diff(entity, diff)
    if (added = diff["+"])
      entity["state"] = added["s"] if added.key?("s")
      entity["last_changed"] = added["lc"] if added.key?("lc")
      entity["last_updated"] = added["lu"] if added.key?("lu")

      if added.key?("a")
        entity["attributes"] ||= {}
        entity["attributes"].merge!(added["a"])
      end

      if added.key?("c")
        entity["context"] ||= {}
        entity["context"].merge!(added["c"])
      end
    end

    if (removed = diff["-"])
      if removed.key?("a")
        Array(removed["a"]).each { |key| entity["attributes"]&.delete(key) }
      end

      if removed.key?("c")
        Array(removed["c"]).each { |key| entity["context"]&.delete(key) }
      end
    end
  end

  def persist_states
    api = HomeAssistantApi.new(@config, store: @store)
    api.save_states(@entities.values)
  end

  def broadcast
    begin
      Rails.application.executor.wrap do
        DisplayBroadcaster.broadcast_all_mira_displays
      end
    rescue => e
      Rails.logger.error "[HA WebSocket] Broadcast failed: #{e.message}"
    end
  end

  def send_message(data)
    @ws&.send(data.to_json)
  end
end
