# frozen_string_literal: true

class SonosSystem
  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 1.minute
  end

  def self.data
    MemoryValue.get(:sonos)[:data] || {}
  end

  def self.last_fetched_at
    MemoryValue.get(:sonos)[:last_fetched_at]
  end

  def self.status
    return nil unless data["playbackState"] == "PLAYING" && data["currentTrack"]["title"].present?

    if data["currentTrack"]["artist"].include?("WKSU-HD2")
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
    response = HTTParty.get(Timeframe::Application.config.local["node_sonos_http_api_url"])

    return if response["status"] == "error"

    MemoryValue.upsert(:sonos,
      {
        data: response,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      })
  end
end
