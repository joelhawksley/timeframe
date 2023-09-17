# frozen_string_literal: true

class SonosSystem
  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 1.minute
  end

  def self.data
    Value.find_or_create_by(key: "sonos").value["data"] || {}
  end

  def self.last_fetched_at
    Value.find_or_create_by(key: "sonos").value["last_fetched_at"]
  end

  def self.status
    return nil unless data["playbackState"] == "PLAYING" && data["currentTrack"]["title"].present?

    if data["currentTrack"]["title"].split(" - ").length == 3 # if title is track/artist/album
      title_parts = data["currentTrack"]["title"].split(" - ")

      {
        artist: title_parts[1],
        track: title_parts[0]
      }
    else
      {
        artist: data["currentTrack"]["artist"],
        track: data["currentTrack"]["title"]
      }
    end
  end

  def self.fetch
    Value.upsert({ key: "sonos", value:
      {
        data: JSON.parse(HTTParty.get(Timeframe::Application.config.local["node_sonos_http_api_url"]).body),
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    }, unique_by: :key)
  end
end