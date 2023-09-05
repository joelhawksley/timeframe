# frozen_string_literal: true

class SonosService
  def self.healthy?
    return true unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 1.minute
  end

  def self.data
    Value.find_or_create_by(key: "sonos").value["data"] || {}
  end

  def self.last_fetched_at
    Value.find_or_create_by(key: "sonos").value["last_fetched_at"]
  end

  def self.status
    return nil unless data["playbackState"] == "PLAYING"

    {
      artist: data["currentTrack"]["artist"],
      track: data["currentTrack"]["title"]
    }
  end

  def self.fetch
    Value.upsert({ key: "sonos", value:
      {
        data: JSON.parse(HTTParty.get(Timeframe::Application.config.local["node_sonos_http_api_url"]).body),
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    }, unique_by: :key)
  rescue => e
    Log.create(
      globalid: "SonosService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end
end