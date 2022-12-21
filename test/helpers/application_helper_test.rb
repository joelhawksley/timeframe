require 'test_helper'

class HelperTests
  include ApplicationHelper
end

class ApplicationHelperTest < Minitest::Test
  def setup
    @helper = HelperTests.new
  end

  def test_pregnancy_string
    assert_equal(@helper.pregnancy_string(Date.parse("2022-12-21")), "11w4d")
  end

  def test_events_weather_alert
    weather =
      {
        "nws_alerts" => {
          "features" => [
            {
              "properties" => {
                "effective" => Time.at(1627060200).to_s,
                "title" => "Air Quality Alert",
                "expires" => Time.at(1627077600).to_s,
                "severity" => "Severe",
                "description" => "...ALERT....\n"
              }
            }
          ]
        }
      }

    Value.upsert({ key: "weather", value: weather }, unique_by: :key)

    result = @helper.calendar_events_for(1627060000, 1627077800)

    assert_equal(1, result.length)
    assert_equal("11:10a - 4p", result[0]["time"])
  end

  def test_weather_duplicate_titles
    weather = {
      "nws_alerts" => {
        "features" => [
          {
            "properties" => {
              "effective" => Time.at(1627770120).to_s,
              "event" => "Flash Flood Warning",
              "expires" => Time.at(1627778700).to_s,
              "regions" => ["Boulder"],
              "severity" => "Severe"
            }
          },
          {
            "properties" => {
              "effective" => Time.at(1627762260).to_s,
              "event" => "Flash Flood Watch",
              "expires" => Time.at(1627786800).to_s,
              "severity" => "Moderate"
            }
          }
        ]
      }
    }

    Value.upsert({ key: "weather", value: weather }, unique_by: :key)

    result = @helper.calendar_events_for(1627060000, 1627855200)

    assert_equal(1, result.length)
    assert_equal("Flash Flood Warning", result[0]["summary"])
  end

  def test_calendar_events_single_event
    start_i = 1621288800
    end_i = 1621292400

    events = [
      {
        start_i: start_i, # 4pm
        end_i: end_i # 5pm
      }
    ]

    Value.upsert({ key: "calendar_events", value: events }, unique_by: :key)

    result = @helper.calendar_events_for(start_i, end_i)

    assert_equal(1, result.length)
    assert_equal("4 - 5p", result[0]["time"])
  end

  def test_calendar_events_exclusion
    excluded_start_i = 1621281700
    excluded_end_i = 1621288700

    included_start_i = 1621288800
    included_end_i = 1621292400

    events = [
      {
        start_i: excluded_start_i,
        end_i: excluded_end_i
      },
      {
        start_i: included_start_i,
        end_i: included_end_i
      }
    ]

    Value.upsert({ key: "calendar_events", value: events }, unique_by: :key)

    result = @helper.calendar_events_for(included_start_i, included_end_i)

    assert_equal(1, result.length)
    assert_equal(included_start_i, result[0]["start_i"])
  end

  def test_render_json_payload_empty
    result = @helper.render_json_payload(DateTime.new(2001, 2, 3, 4, 5, 6))

    assert_equal("Friday at 9:05 PM", result[:timestamp])
    assert_equal({}, result[:yearly_events])
    assert_equal(6, result[:day_groups].length)
    assert_equal({}, result[:emails])
  end

  # def test_render_json_emails
  #   emails = [
  #     {"from" => "no-reply@thriftbooks.com", "subject" => "Order Confirmation - Thriftbooks.com"},
  #     {"from" => "Old Navy Customer Service <custserv@oldnavy.com>"},
  #     {"from" => "Christ the Servant Lutheran Church <cts.communications@gmail.com>"},
  #     {"from" => "Ruby Weekly <rw@peterc.org>"},
  #     {"from" => "Nate Berkopec <nate.berkopec@speedshop.co>"},
  #     {"from" => "notifier <exceptions@solofolio.net>"},
  #     {"from" => "notifier <exceptions@solofolio.net>"},
  #     {"from" => "Jim <mt@gmail.com>"}
  #   ]

  #   result =
  #     User
  #       .new(google_accounts: [GoogleAccount.new(emails: emails)])
  #       .render_json_payload[:emails]

  #   expected_result =
  #     {
  #       "thriftbooks.com" => 1,
  #       "Old Navy Customer Service" => 1,
  #       "Christ the Servant Lutheran Church" => 1,
  #       "Ruby Weekly" => 1,
  #       "Nate Berkopec" => 1,
  #       "notifier" => 2,
  #       "Jim" => 1
  #     }

  #   assert_equal(expected_result, result)
  # end

  def test_render_json_weather
    weather = {
      "nearby" => {
        "imperial" => {
          "temp" => 89.02
        }
      },
      "currently" => {
        "icon" => "partly-cloudy-day",
        "time" => 1622930480,
        "ozone" => 310.2,
        "summary" => "Partly Cloudy",
        "uvIndex" => 5,
        "dewPoint" => 45.08,
        "humidity" => 0.22,
        "pressure" => 1001.4,
        "windGust" => 11.55,
        "windSpeed" => 4.68,
        "cloudCover" => 0.51,
        "visibility" => 10,
        "temperature" => 89.12,
        "windBearing" => 261,
        "precipIntensity" => 0,
        "precipProbability" => 0,
        "apparentTemperature" => 89.12,
        "nearestStormBearing" => 242,
        "nearestStormDistance" => 9
      },
      "daily" => {
        "data" => [{
          "icon" => "partly-cloudy-day",
          "time" => 1622872800,
          "ozone" => 310.4,
          "summary" => "Partly cloudy throughout the day.",
          "uvIndex" => 10,
          "dewPoint" => 45.11,
          "humidity" => 0.37,
          "pressure" => 1003.8,
          "windGust" => 22.16,
          "moonPhase" => 0.87,
          "windSpeed" => 5.26,
          "cloudCover" => 0.35,
          "precipType" => "rain",
          "sunsetTime" => 1622946420,
          "visibility" => 10,
          "sunriseTime" => 1622892840,
          "uvIndexTime" => 1622917560,
          "windBearing" => 263,
          "windGustTime" => 1622939040,
          "temperatureLow" => 58.86,
          "temperatureMax" => 91.67,
          "temperatureMin" => 58.42,
          "precipIntensity" => 0.0011,
          "temperatureHigh" => 91.67,
          "precipProbability" => 0.08,
          "precipAccumulation" => 1.08,
          "precipIntensityMax" => 0.0091,
          "temperatureLowTime" => 1622979660,
          "temperatureMaxTime" => 1622926440,
          "temperatureMinTime" => 1622893440,
          "temperatureHighTime" => 1622926440,
          "apparentTemperatureLow" => 59.35,
          "apparentTemperatureMax" => 91.17,
          "apparentTemperatureMin" => 58.91,
          "precipIntensityMaxTime" => 1622941080,
          "apparentTemperatureHigh" => 91.17,
          "apparentTemperatureLowTime" => 1622979660,
          "apparentTemperatureMaxTime" => 1622926440,
          "apparentTemperatureMinTime" => 1622893440,
          "apparentTemperatureHighTime" => 1622926440
        }]
      }
    }

    Value.upsert({ key: "weather", value: weather }, unique_by: :key)

    result = @helper.render_json_payload(DateTime.new(2021, 6, 5, 4, 5, 6))

    assert_equal("89°", result[:current_temperature])

    first_day_group = result[:day_groups][0]

    assert_equal("partly-cloudy-day", first_day_group[:weather_icon])
    assert_equal(" 1\"", first_day_group[:precip_label])
    assert_equal(0.08, first_day_group[:precip_probability])
    assert_equal(22, first_day_group[:wind])
  end

  def test_yearly_events_empty_case
    assert_equal({}, @helper.yearly_events)
  end

  def test_yearly_events
    yearly_event = {
      "end" => {"date" => "2021-06-03"},
      "end_i" => 1622699999,
      "start_i" => 1622613600,
      "start" => {"date" => "2021-06-02"},
      "summary" => "Len Inderhees (62)",
      "calendar" => "Birthdays"
    }

    Value.upsert({ key: "calendar_events", value: [yearly_event] }, unique_by: :key)

    result = @helper.yearly_events(Time.new(2021, 6, 1))

    assert_equal([6], result.keys)
    assert_equal("Len Inderhees (62)", result[6][0]["summary"])
  end

  def test_yearly_events_excludes_non_birthday
    yearly_event = {
      "end" => {"date" => "2021-06-03"},
      "end_i" => 1622699999,
      "start_i" => 1622613600,
      "start" => {"date" => "2021-06-02"},
      "summary" => "Len Inderhees (62)",
      "calendar" => "Foo"
    }

    Value.upsert({ key: "calendar_events", value: [yearly_event] }, unique_by: :key)

    result = @helper.yearly_events(Time.new(2021, 6, 1))

    refute result.present?
  end
end