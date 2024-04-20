# frozen_string_literal: true

require "test_helper"

class SonosSystemTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:sonos_fetch, match_requests_on: [:method]) do
      SonosSystem.fetch
    end
  end

  def test_health_no_data
    SonosSystem.stub :last_fetched_at, nil do
      assert(!SonosSystem.healthy?)
    end
  end

  def test_health_current_data
    SonosSystem.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(SonosSystem.healthy?)
      end
    end
  end

  def test_health_stale_data
    SonosSystem.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(SonosSystem.healthy?)
      end
    end
  end

  def test_status
    data = {
      "mute" => false,
      "volume" => 11,
      "trackNo" => 1,
      "playMode" => {"repeat" => "none", "shuffle" => false, "crossfade" => false},
      "equalizer" => {"bass" => 0, "treble" => 0, "loudness" => true},
      "nextTrack" =>
        {"uri" => "x-sonos-spotify:spotify%3atrack%3a0feAWJwUTkLVcTIhYx473T?sid=12&flags=8232&sn=2",
         "album" => "fabric presents Maribou State (DJ Mix)",
         "title" => "Yefkir Engurguro - Mixed",
         "artist" => "Hailu Mergia",
         "duration" => 224,
         "trackUri" => "x-sonos-spotify:spotify%3atrack%3a0feAWJwUTkLVcTIhYx473T?sid=12&flags=8232&sn=2",
         "albumArtUri" =>
          "/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a0feAWJwUTkLVcTIhYx473T%3fsid%3d12%26flags%3d8232%26sn%3d2",
         "absoluteAlbumArtUri" =>
          "http://192.168.1.189:1400/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a0feAWJwUTkLVcTIhYx473T%3fsid%3d12%26flags%3d8232%26sn%3d2"},
      "elapsedTime" => 0,
      "currentTrack" =>
        {"uri" => "x-sonos-spotify:spotify%3atrack%3a4OHJmCwMAexvmRsBWToZMP?sid=12&flags=8232&sn=2",
         "type" => "track",
         "album" => "American Tunes",
         "title" => "Southern Nights",
         "artist" => "Allen Toussaint",
         "duration" => 210,
         "trackUri" => "x-sonos-spotify:spotify%3atrack%3a4OHJmCwMAexvmRsBWToZMP?sid=12&flags=8232&sn=2",
         "albumArtUri" =>
          "/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a4OHJmCwMAexvmRsBWToZMP%3fsid%3d12%26flags%3d8232%26sn%3d2",
         "stationName" => "",
         "absoluteAlbumArtUri" =>
          "https://seed-mix-image.spotifycdn.com/v6/img/desc/Afternoon%20Classical%20Piano/en/large"},
      "playbackState" => "PLAYING",
      "elapsedTimeFormatted" => "00:00:00"
    }

    SonosSystem.stub :data, data do
      assert_equal({artist: "Allen Toussaint", track: "Southern Nights"}, SonosSystem.status)
    end
  end

  def test_folk_alley_status
    data = {
      "currentTrack" =>
       {"album" => "American Tunes",
        "title" => "Masterfade - Andrew Bird - The Mysterious Production of Eggs",
        "artist" => "Folk Alley - WKSU-HD2"},
      "playbackState" => "PLAYING"
    }

    SonosSystem.stub :data, data do
      assert_equal({artist: "Andrew Bird", track: "Masterfade"}, SonosSystem.status)
    end
  end

  def test_cpr_news_status
    data = {
      "currentTrack" =>
       {"artist"=>"Colorado Public Radio News"},
      "playbackState" => "PLAYING"
    }

    SonosSystem.stub :data, data do
      assert_equal({artist: "CPR News", track: nil}, SonosSystem.status)
    end
  end

  def test_status_no_title
    data = {
      "currentTrack" =>
       {"album" => "American Tunes",
        "artist" => "Folk Alley - WKSU-HD2"},
      "playbackState" => "PLAYING"
    }

    SonosSystem.stub :data, data do
      assert_equal({artist: "Folk Alley", track: "American Tunes"}, SonosSystem.status)
    end
  end
end
