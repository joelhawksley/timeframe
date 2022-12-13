# frozen_string_literal: true

class WeatherService
  def self.call(user)
    result = HTTParty.get("https://api.darksky.net/forecast/#{ENV["DARK_SKY_API_KEY"]}/39.9147082,-105.0220883?extend=hourly")

    result["nearby"] = HTTParty.get("https://api.weather.com/v2/pws/observations/current?apiKey=dfcb91ac7fef48198b91ac7fef18199a&format=json&units=e&stationId=KCOWESTM190")["observations"].first

    result["weatherflow_forecast"] = HTTParty.get("https://swd.weatherflow.com/swd/rest/better_forecast?station_id=89356&units_temp=f&units_wind=mph&units_pressure=mb&units_precip=in&units_distance=mi&token=3bf5c711-54e6-45f4-9c74-1389f0727244")

    result["nws_alerts"] = JSON.parse(HTTParty.get('https://api.weather.gov/alerts/active/zone/COZ040', { headers: {"User-Agent" => "joel@hawksley.org"} }))

    user.update(weather: result.as_json)
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
