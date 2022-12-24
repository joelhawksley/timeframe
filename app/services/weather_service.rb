# frozen_string_literal: true

class WeatherService
  def self.call
    result = HTTParty.get("https://api.darksky.net/forecast/#{ENV["DARK_SKY_API_KEY"]}/39.9147082,-105.0220883?extend=hourly").to_h

    result["nearby"] = HTTParty.get("https://api.weather.com/v2/pws/observations/current?apiKey=#{Rails.application.config.app.wunderground_token}&format=json&units=e&stationId=KCOWESTM190")["observations"].first

    result["weatherflow_forecast"] = HTTParty.get("https://swd.weatherflow.com/swd/rest/better_forecast?station_id=89356&units_temp=f&units_wind=mph&units_pressure=mb&units_precip=in&units_distance=mi&token=#{Rails.application.config.app.weatherflow_token}")

    result["nws_alerts"] = JSON.parse(HTTParty.get('https://api.weather.gov/alerts/active/zone/COZ040', { headers: {"User-Agent" => "joel@hawksley.org"} }))

    result["nws_hourly"] =
      JSON.parse(
        HTTParty.get(
          'https://api.weather.gov/gridpoints/BOU/61,69/forecast/hourly',
          { headers: {"User-Agent" => "joel@hawksley.org"} }
        )
      )["properties"]["periods"].map do |period|
        {
          start_i: Time.parse(period["startTime"]).to_i,
          end_i: Time.parse(period["endTime"]).to_i,
          temperature: period["temperature"],
          wind: period["windSpeed"],
          short_forecast: period["shortForecast"]
        }
      end

    # https://api.weather.gov/gridpoints/BOU/61,69/forecast

    Value.find_by_key("weather").update(value: result)

    Log.create(
      globalid: "WeatherService",
      event: "call_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: "WeatherService",
      event: "call_error",
      message: e.message
    )
  end
end
