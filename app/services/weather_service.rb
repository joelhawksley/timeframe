# frozen_string_literal: true

class WeatherService
  def self.call(debug = false)
    result = {}

    result["nearby"] = HTTParty.get("https://api.weather.com/v2/pws/observations/current?apiKey=#{Rails.application.config.app.wunderground_token}&format=json&units=e&stationId=KCOWESTM190")["observations"].first

    result["wunderground_forecast"] = HTTParty.get("https://api.weather.com/v3/wx/forecast/daily/5day?geocode=39.9147082,-105.0220883&format=json&units=e&language=en-US&apiKey=#{Rails.application.config.app.wunderground_token}")

    result["weatherflow_forecast"] = HTTParty.get("https://swd.weatherflow.com/swd/rest/better_forecast?station_id=89356&units_temp=f&units_wind=mph&units_pressure=mb&units_precip=in&units_distance=mi&token=#{Rails.application.config.app.weatherflow_token}")

    result["nws_alerts"] = JSON.parse(HTTParty.get('https://api.weather.gov/alerts/active/zone/COZ040', { headers: {"User-Agent" => "joel@hawksley.org"} }))

    nws_hourly_response = JSON.parse(
      HTTParty.get(
        'https://api.weather.gov/gridpoints/BOU/61,69/forecast/hourly',
        { headers: {"User-Agent" => "joel@hawksley.org"} }
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
          day_part = period["icon"].split("/")[-2]
          icon = period["icon"].split("?").first.split("/").last

          icon_class = 
            if day_part == "day"
              case icon
              when "few"
                "fa-solid fa-sun"
              when "bkn", "sct"
                "fa-solid fa-cloud-sun"
              when "ovc"
                "fa-solid fa-cloud"
              when "snow"
                "fa-solid fa-snowflake"
              else
                "fa-solid fa-question"
              end
            else 
              case icon
              when "few"
                "fa-solid fa-moon"
              when "bkn", "sct"
                "fa-solid fa-cloud-moon"
              when "ovc"
                "fa-solid fa-cloud"
              when "snow"
                "fa-solid fa-snowflake"
              else
                "fa-solid fa-question"
              end
            end


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
      message: e.message
    )
  end
end
