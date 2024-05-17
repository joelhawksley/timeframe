# frozen_string_literal: true

require "test_helper"

class DogParkApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:dogpark_fetch, match_requests_on: [:method]) do
      DogParkApi.fetch
    end
  end

  def test_last_fetched_at_no_data
    DaybreakValue.stub(:get, {}) do
      assert_nil(DogParkApi.last_fetched_at)
    end
  end

  def test_health_no_data
    DogParkApi.stub :last_fetched_at, nil do
      assert(!DogParkApi.healthy?)
    end
  end

  def test_health_current_data
    DogParkApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(DogParkApi.healthy?)
      end
    end
  end

  def test_health_stale_data
    DogParkApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(DogParkApi.healthy?)
      end
    end
  end

  def test_open_no_data
    DogParkApi.stub(:data, {}) do
      assert_equal(DogParkApi.open?, false)
    end
  end

  def test_open
    data = "PrintFeedbackShare & BookmarkShare & Bookmark, Press Enter to show all options, press Tab go to next optionFont Size: + -
    THE DOG OFF-LEASH AREA AT DAVIDSON MESA IS OPEN.

     The HOWL Line is currently experiencing technical difficulties. Please check back here for updates."

    DogParkApi.stub :data, data do
      assert(DogParkApi.open?)
    end
  end
end
