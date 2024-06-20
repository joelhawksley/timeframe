# frozen_string_literal: true

require "test_helper"

class SonosApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:sonos_fetch, match_requests_on: [:method]) do
      SonosApi.new.fetch
    end
  end

  def test_health_no_data
    api = SonosApi.new
    api.stub :last_fetched_at, nil do
      assert(!api.healthy?)
    end
  end

  def test_health_current_data
    api = SonosApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(api.healthy?)
      end
    end
  end

  def test_health_stale_data
    api = SonosApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(api.healthy?)
      end
    end
  end

  def test_status
    data = {
      currentTrack: {album: "American Tunes",
                     title: "Southern Nights",
                     artist: "Allen Toussaint"},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "Allen Toussaint", track: "Southern Nights"}, api.status)
    end
  end

  def test_folk_alley_status
    data = {
      currentTrack: {album: "American Tunes",
                     title: "Masterfade - Andrew Bird - The Mysterious Production of Eggs",
                     artist: "Folk Alley - WKSU-HD2"},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "Andrew Bird", track: "Masterfade"}, api.status)
    end
  end

  def test_cpr_news_status
    data = {
      currentTrack: {artist: "Colorado Public Radio News"},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "CPR News", track: nil}, api.status)
    end
  end

  def test_cpr_classical_status
    data = {
      currentTrack: {artist: "Colorado Public Radio Classical",
                     title: "Slavonic Dance #5 in bb Op 72/5 by Antonin Dvorak -- Dvorak: Slavonic Dances / Dorati, Royal Po"},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "Antonin Dvorak", track: "Slavonic Dance #5 in bb Op 72/5"}, api.status)
    end
  end

  def test_cpr_classical_break_status
    data = {
      currentTrack: {
        artist: "Colorado Public Radio Classical",
        title: "CPR Classical -- Essential Saturdays"
      },
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "CPR Classical", track: "Essential Saturdays"}, api.status)
    end
  end

  def test_status_no_title
    data = {
      currentTrack: {album: "American Tunes",
                     artist: "Folk Alley - WKSU-HD2"},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_equal({artist: "Folk Alley", track: "American Tunes"}, api.status)
    end
  end

  def test_nil_case_april_23
    data = {
      currentTrack: {album: nil,
                     artist: nil},
      playbackState: "PLAYING"
    }

    api = SonosApi.new
    api.stub :data, data do
      assert_nil(api.status)
    end
  end
end
