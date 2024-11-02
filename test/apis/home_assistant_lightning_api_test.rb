# frozen_string_literal: true

require "test_helper"

class HomeAssistantLightningApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:home_assistant_lightning_states) do
      travel_to DateTime.new(2024, 11, 1, 15, 15, 0, "-0600") do
        api = HomeAssistantLightningApi.new
        api.fetch

        assert(api.data.length == 1)
      end
    end
  end

  def test_miles_unknown
    api = HomeAssistantLightningApi.new

    data = [
      [
        {entity_id: "sensor.blitzortung_lightning_distance",
         state: "unknown",
         attributes: {lat: 40.664612,
                      lon: -106.736329,
                      unit_of_measurement: "mi",
                      device_class: "distance",
                      friendly_name: "Blitzortung Lightning distance"},
         last_changed: "2024-11-01T20:45:00+00:00",
         last_reported: "2024-11-01T20:45:00+00:00",
         last_updated: "2024-11-01T20:45:00+00:00",
         context: {id: "01JB7AHGJ001BVZJP660G9JKXA", parent_id: nil, user_id: nil}}
      ]
    ]

    api.stub :data, data do
      assert_nil(api.distance)
    end
  end

  def test_miles_close
    api = HomeAssistantLightningApi.new

    data = [
      [
        {entity_id: "sensor.blitzortung_lightning_distance",
         state: "10.2",
         attributes: {lat: 40.664612,
                      lon: -106.736329,
                      unit_of_measurement: "mi",
                      device_class: "distance",
                      friendly_name: "Blitzortung Lightning distance"},
         last_changed: "2024-11-01T20:45:00+00:00",
         last_reported: "2024-11-01T20:45:00+00:00",
         last_updated: "2024-11-01T20:45:00+00:00",
         context: {id: "01JB7AHGJ001BVZJP660G9JKXA", parent_id: nil, user_id: nil}}
      ]
    ]

    api.stub :data, data do
      assert_equal(api.distance, "10mi")
    end
  end
end
