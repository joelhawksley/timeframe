# frozen_string_literal: true

require "test_helper"

class DogParkTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:dogpark_fetch, match_requests_on: [:method]) do
      DogPark.fetch
    end

    MemoryValue.upsert(:dogpark, {})
  end

  def test_last_fetched_at
    assert_nil(DogPark.last_fetched_at)
  end

  def test_health_no_data
    DogPark.stub :last_fetched_at, nil do
      assert(!DogPark.healthy?)
    end
  end

  def test_health_current_data
    DogPark.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(DogPark.healthy?)
      end
    end
  end

  def test_health_stale_data
    DogPark.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(DogPark.healthy?)
      end
    end
  end

  def test_open_no_data
    assert_equal(DogPark.open?, false)
  end

  def test_open
    data = "PrintFeedbackShare & BookmarkShare & Bookmark, Press Enter to show all options, press Tab go to next optionFont Size: + -
    THE DOG OFF-LEASH AREA AT DAVIDSON MESA IS OPEN.

     The HOWL Line is currently experiencing technical difficulties. Please check back here for updates."

    DogPark.stub :data, data do
      assert(DogPark.open?)
    end
  end
end
