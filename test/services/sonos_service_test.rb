# frozen_string_literal: true

require "test_helper"

class SonosServiceTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:sonos_fetch, match_requests_on: [:method]) do
      SonosService.fetch
    end
  end

  def test_status
    data = {
      "mute"=>false,
       "volume"=>11,
       "trackNo"=>1,
       "playMode"=>{"repeat"=>"none", "shuffle"=>false, "crossfade"=>false},
       "equalizer"=>{"bass"=>0, "treble"=>0, "loudness"=>true},
       "nextTrack"=>
        {"uri"=>"x-sonos-spotify:spotify%3atrack%3a0feAWJwUTkLVcTIhYx473T?sid=12&flags=8232&sn=2",
         "album"=>"fabric presents Maribou State (DJ Mix)",
         "title"=>"Yefkir Engurguro - Mixed",
         "artist"=>"Hailu Mergia",
         "duration"=>224,
         "trackUri"=>"x-sonos-spotify:spotify%3atrack%3a0feAWJwUTkLVcTIhYx473T?sid=12&flags=8232&sn=2",
         "albumArtUri"=>
          "/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a0feAWJwUTkLVcTIhYx473T%3fsid%3d12%26flags%3d8232%26sn%3d2",
         "absoluteAlbumArtUri"=>
          "http://192.168.1.189:1400/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a0feAWJwUTkLVcTIhYx473T%3fsid%3d12%26flags%3d8232%26sn%3d2"},
       "elapsedTime"=>0,
       "currentTrack"=>
        {"uri"=>"x-sonos-spotify:spotify%3atrack%3a4OHJmCwMAexvmRsBWToZMP?sid=12&flags=8232&sn=2",
         "type"=>"track",
         "album"=>"American Tunes",
         "title"=>"Southern Nights",
         "artist"=>"Allen Toussaint",
         "duration"=>210,
         "trackUri"=>"x-sonos-spotify:spotify%3atrack%3a4OHJmCwMAexvmRsBWToZMP?sid=12&flags=8232&sn=2",
         "albumArtUri"=>
          "/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a4OHJmCwMAexvmRsBWToZMP%3fsid%3d12%26flags%3d8232%26sn%3d2",
         "stationName"=>"",
         "absoluteAlbumArtUri"=>
          "https://seed-mix-image.spotifycdn.com/v6/img/desc/Afternoon%20Classical%20Piano/en/large"},
       "playbackState"=>"PLAYING",
       "elapsedTimeFormatted"=>"00:00:00"}

    SonosService.stub :data, data do
      assert_equal({ artist: "Allen Toussaint", track: "Southern Nights" }, SonosService.status)
    end
  end
end