# frozen_string_literal: true

class SonosApi < Api
  def self.time_before_unhealthy
    1.minute
  end

  def self.prepare_response(response)
    response.to_h
  end

  def self.status
    return nil unless data["playbackState"] == "PLAYING"
    return nil unless data["currentTrack"]["artist"].present?

    if data["currentTrack"]["artist"] == "Colorado Public Radio News"
      {
        artist: "CPR News",
        track: data["currentTrack"]["title"].present? ? (data["currentTrack"]["title"].split(" -- ").last.split("|").first) : nil
      }
    elsif data["currentTrack"]["artist"] == "Colorado Public Radio Classical"
      if data["currentTrack"]["title"].include?(" by ")
        track, artist = data["currentTrack"]["title"].split(" -- ").first.split(" by ")
      else
        artist, track = data["currentTrack"]["title"].split(" -- ")
      end

      {
        artist: artist,
        track: track
      }
    elsif data["currentTrack"]["artist"].include?("WKSU-HD2")
      if data["currentTrack"]["title"].present?
        title_parts = data["currentTrack"]["title"].split(" - ")

        {
          artist: title_parts[1],
          track: title_parts[0]
        }
      else
        {
          artist: data["currentTrack"]["artist"].split(" - ").first,
          track: data["currentTrack"]["album"]
        }
      end
    else
      {
        artist: data["currentTrack"]["artist"],
        track: data["currentTrack"]["title"]
      }
    end
  end
end
