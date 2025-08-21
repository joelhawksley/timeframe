class HomeAssistantApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def prepare_response(response)
    entity_ids = @config["home_assistant"].values.flatten

    # Only save entity states we are interested in vs. all 1000+ entities
    response.filter do
      entity_ids.include?(it["entity_id"]) ||
        it["entity_id"].include?("sensor.timeframe") ||
        it["state"] == "unavailable" && !it["entity_id"].include?("image.")
    end
  end

  def demo_mode?
    return false unless @config["home_assistant"].present?

    entity = data.find { it[:entity_id] == @config["home_assistant"]["demo_mode_entity_id"] }
    return false unless entity.present?

    entity[:state] == "on"
  end

  def problems
    timeframe_sensor_problems = data
      .select { it[:entity_id].include?("sensor.timeframe") }
      .map do
        if it[:state].include?(",")
          it[:state].split("\n").map(&:strip).reject(&:empty?).map do |line|
            {
              icon: line.split(",").first.strip,
              message: line.split(",").last.strip
            }
          end
        elsif it[:state] == "on"
          _, icon, raw_message = it[:entity_id].split("0")

          {
            icon: icon.tr("_", "-"),
            message: raw_message.tr("_", " ").humanize
          }
        elsif !["on", "off", ""].include?(it[:state])
          _, icon, _ = it[:entity_id].split("0")

          {
            icon: icon.tr("_", "-"),
            message: it[:state].humanize
          }
        end
      end.flatten.compact

    unavailable_entity_problems = data
      .select {
        it[:state] == "unavailable" &&
          Time.parse(it[:last_updated].to_s) < 15.minutes.ago &&
          !@config.dig("home_assistant", "allowed_unavailable").to_a.include?(it[:entity_id])
      }

    if unavailable_entity_problems.any?
      message = "#{unavailable_entity_problems[0][:entity_id].split(".").last.humanize} unavailable"

      if unavailable_entity_problems.size > 1
        message += " +#{unavailable_entity_problems.size - 1}"
      end

      unavailable_entity_problems = [
        {
          icon: "triangle-exclamation",
          message: message
        }
      ]
    end

    timeframe_sensor_problems + unavailable_entity_problems
  end

  def now_playing
    entity = data.find { it[:entity_id] == @config["home_assistant"]["media_player_entity_id"] }

    return {} unless entity.present?
    return {} if entity[:state] == "paused" || entity[:state] == "idle"

    if entity.dig(:attributes, :media_artist)&.include?("CPR News")
      {
        artist: "CPR News",
        track: entity.dig(:attributes, :media_title).split(" -- ").last
      }
    elsif entity.dig(:attributes, :media_channel)&.include?("Colorado Public Radio Classical")
      track, artist = entity.dig(:attributes, :media_title).split(" -- ").first.split(" by ")

      {
        artist: artist,
        track: track
      }
    elsif entity.dig(:attributes, :media_channel)&.include?("WKSU-HD2")
      title_parts = entity.dig(:attributes, :media_title).split(" - ")

      {
        artist: title_parts[0],
        track: title_parts[1]
      }
    else
      {
        artist: entity.dig(:attributes, :media_artist),
        track: entity.dig(:attributes, :media_title)
      }
    end
  end

  def time_before_unhealthy
    1.minute
  end

  def feels_like_temperature
    entity = data.find { it[:entity_id] == @config["home_assistant"]["weather_feels_like_entity_id"] }

    return nil unless entity.present?

    "#{entity[:state].to_i}°"
  end
end
