# frozen_string_literal: true

class WeatherService
  def self.call(debug = false)
    result = {}

    result["nearby"] = HTTParty.get(
      "https://api.weather.com/v2/pws/observations/current?apiKey=" \
      "#{ENV["WUNDERGROUND_TOKEN"]}&format=json&units=e&stationId=#{ENV['WUNDERGROUND_STATION_ID']}"
    )["observations"].first

    result["wunderground_forecast"] = HTTParty.get(
      "https://api.weather.com/v3/wx/forecast/daily/5day?geocode=#{ENV["LAT_LONG"]}" \
      "&format=json&units=e&language=en-US&apiKey=#{ENV["WUNDERGROUND_TOKEN"]}"
    )

    result["weatherflow_forecast"] = HTTParty.get(
      "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=#{ENV['WEATHERFLOW_STATION_ID']}" \
      "&units_temp=f&units_wind=mph&units_pressure=mb&units_precip=in&units_distance=mi" \
      "&token=#{ENV["WEATHERFLOW_TOKEN"]}"
    )

    result["nws_alerts"] = JSON.parse(
      HTTParty.get(
        "https://api.weather.gov/alerts/active/zone/#{ENV['NWS_ZONE']}",
        {headers: {"User-Agent" => "joel@hawksley.org"}}
      )
    )

    nws_hourly_response = JSON.parse(
      HTTParty.get(
        "https://api.weather.gov/gridpoints/#{ENV['NWS_GRIDPOINT']}/forecast/hourly",
        {headers: {"User-Agent" => "joel@hawksley.org"}}
      )
    )

    result["nws_hourly"] =
      if nws_hourly_response["status"] == 503
        Log.create(
          globalid: "WeatherService",
          event: "nws_hourly_error",
          message: "NWS hourly API returned a 503"
        )

        # Just use old value
        Value.weather["nws_hourly"]
      else
        nws_hourly_response["properties"]["periods"].map do |period|
          icon, icon_class = icon_for_period(period["icon"])

          binding.irb if debug

          {
            start_i: Time.parse(period["startTime"]).to_i,
            end_i: Time.parse(period["endTime"]).to_i,
            temperature: period["temperature"],
            wind: period["windSpeed"],
            short_forecast: period["shortForecast"],
            icon: icon,
            icon_class: icon_class
          }
        end
      end

    Value.find_by_key("weather").update(value: result)

    Log.create(
      globalid: "WeatherService",
      event: "call_success",
      message: ""
    )
  rescue => e
    binding.irb if debug

    Log.create(
      globalid: "WeatherService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  MAPPINGS = {
    "/day/ovc" => "fa-solid fa-clouds",
    "/day/bkn" => "fa-solid fa-clouds-sun",
    "/day/sct" => "fa-solid fa-cloud-sun",
    "/day/few" => "fa-solid fa-sun",
    "/day/wind_bkn" => "fa-solid fa-wind",
    "/day/wind_few" => "fa-solid fa-wind",
    "/day/wind_sct" => "fa-solid fa-wind",
    "/day/rain" => "fa-solid fa-cloud-rain",
    "/day/snow" => "fa-solid fa-cloud-snow",
    "/day/cold" => "fa-solid fa-hat-winter",
    "/night/bkn" => "fa-solid fa-clouds-moon",
    "/night/sct" => "fa-solid fa-cloud-moon",
    "/night/few" => "fa-solid fa-moon",
    "/night/wind_bkn" => "fa-solid fa-wind",
    "/night/wind_few" => "fa-solid fa-wind",
    "/night/wind_sct" => "fa-solid fa-wind",
    "/night/rain" => "fa-solid fa-cloud-rain",
    "/night/snow" => "fa-solid fa-cloud-snow",
    "/night/cold" => "fa-solid fa-hat-winter",
  }

  def self.icon_for_period(nws_url)
    icon = nws_url.split("?").first.split("/").last

    token = 
      nws_url.split("?").first.
      split("land").last.
      split(",").first
    
    [icon, MAPPINGS[token] || "fa-solid fa-question"]
  end
end
