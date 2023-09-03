# frozen_string_literal: true

require "test_helper"

class WeatherAlertServiceTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette("WeatherAlertService.fetch") do
      WeatherAlertService.fetch
    end
  end

  # def test_temperature_range_for_example
  #   weather = {
  #     "forecastDaily" => {
  #       "days" => [
  #         {
  #           "forecastStart"=>"2023-08-27T06:00:00Z",
  #           "temperatureMax"=>30.38,
  #           "temperatureMin"=>14.47,
  #         },
  #         {
  #           "forecastStart"=>"2023-08-28T06:00:00Z",
  #           "temperatureMax"=>25.32,
  #           "temperatureMin"=>15.16,
  #         }
  #       ]
  #     }
  #   }

  #   WeatherKitService.stub :weather, weather do
  #     assert_equal("&#8593;87 &#8595;58", WeatherKitService.temperature_range_for(Date.new(2023,8,27)))
  #   end
  # end
end