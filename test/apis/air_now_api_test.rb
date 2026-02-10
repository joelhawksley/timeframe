# frozen_string_literal: true

require "test_helper"

class AirNowApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:airnow_fetch, match_requests_on: [:method]) do
      AirNowApi.new.fetch
    end
  end

  def test_health_no_data
    api = AirNowApi.new
    api.stub :last_fetched_at, nil do
      assert(!api.healthy?)
    end
  end

  def test_health_current_data
    api = AirNowApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(api.healthy?)
      end
    end
  end

  def test_health_stale_data
    api = AirNowApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(api.healthy?)
      end
    end
  end

  def test_daily_calendar_events
    data =
      [
        {
          DateIssue: "2024-07-16",
          DateForecast: "2024-07-16",
          ReportingArea: "Denver-Boulder",
          StateCode: "CO",
          Latitude: 39.9003,
          Longitude: -105.042,
          ParameterName: "O3",
          AQI: -1,
          Category: {Number: 3, Name: "Moderate"},
          ActionDay: false,
          Discussion: ""
        },
        {
          DateIssue: "2024-07-16",
          DateForecast: "2024-07-16",
          ReportingArea: "Denver-Boulder",
          StateCode: "CO",
          Latitude: 39.9003,
          Longitude: -105.042,
          ParameterName: "PM2.5",
          AQI: -1,
          Category: {Number: 1, Name: "Good"},
          ActionDay: false,
          Discussion: ""
        },
        {
          DateIssue: "2024-07-16",
          DateForecast: "2024-07-17",
          ReportingArea: "Denver-Boulder",
          StateCode: "CO",
          Latitude: 39.9003,
          Longitude: -105.042,
          ParameterName: "O3",
          AQI: -1,
          Category: {Number: 2, Name: "Moderate"},
          ActionDay: false,
          Discussion: ""
        },
        {
          DateIssue: "2024-07-16",
          DateForecast: "2024-07-17",
          ReportingArea: "Denver-Boulder",
          StateCode: "CO",
          Latitude: 39.9003,
          Longitude: -105.042,
          ParameterName: "PM2.5",
          AQI: -1,
          Category: {Number: 3, Name: "Good"},
          ActionDay: false,
          Discussion: ""
        }
      ]

    api = AirNowApi.new
    api.stub :last_fetched_at, "2024-07-16 11:03:59 -0600" do
      travel_to DateTime.new(2024, 7, 16, 11, 15, 0, "-0600") do
        api.stub :data, data do
          assert_equal(2, api.daily_calendar_events.length)
        end
      end
    end
  end
end
