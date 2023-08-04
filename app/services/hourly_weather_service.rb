class HourlyWeatherService
  def self.load
    Value.find_or_create_by(key: "hourly_weather").value || {}
  end

  def self.fetch
    result = load

    response = JSON.parse(
      HTTParty.get(
        "https://api.weather.gov/gridpoints/#{ENV['NWS_GRIDPOINT']}/forecast/hourly",
        {headers: {"User-Agent" => "joel@hawksley.org"}}
      )
    )

    if response["status"] == 503
      Log.create(
        globalid: "HourlyWeatherService",
        event: "fetch_error",
        message: "NWS hourly API returned a 503"
      )
    else
      result[:periods] =
        response["properties"]["periods"].map do |period|
          icon, icon_class = icon_for_period(period["icon"])

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

      result[:last_fetched_at] = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
    end

    Value.find_or_create_by(key: "hourly_weather").update(value: result)
  end

  def self.icon_for_period(nws_url)
    icon = nws_url.split("?").first.split("/").last

    token =
      nws_url.split("?").first.
      split("land").last.
      split(",").first

    mappings = {
      "/day/ovc" => "clouds",
      "/day/bkn" => "clouds-sun",
      "/day/sct" => "cloud-sun",
      "/day/few" => "sun",
      "/day/wind_bkn" => "wind",
      "/day/wind_few" => "wind",
      "/day/wind_sct" => "wind",
      "/day/rain" => "raindrops",
      "/day/tsra_hi" => "raindrops",
      "/day/tsra_sct" => "raindrops",
      "/day/tsra" => "raindrops",
      "/day/rain_showers" => "raindrops",
      "/day/snow" => "snowflake",
      "/day/blizzard" => "snowflake",
      "/day/cold" => "hat-winter",
      "/day/fog" => "cloud-fog",
      "/day/skc" => "sun",
      "/day/smoke" => "smoke",
      "/day/hot" => "temperature-high",
      "/night/ovc" => "clouds",
      "/night/bkn" => "clouds-moon",
      "/night/sct" => "cloud-moon",
      "/night/few" => "moon",
      "/night/skc" => "moon",
      "/night/wind_bkn" => "wind",
      "/night/wind_few" => "wind",
      "/night/wind_sct" => "wind",
      "/night/rain" => "raindrops",
      "/night/tsra_hi" => "raindrops",
      "/night/tsra_sct" => "raindrops",
      "/night/tsra" => "raindrops",
      "/night/rain_showers" => "raindrops",
      "/night/snow" => "snowflake",
      "/night/blizzard" => "snowflake",
      "/night/cold" => "hat-winter",
      "/night/fog" => "cloud-fog",
      "/night/smoke" => "smoke",
      "/night/hot" => "temperature-high"
    }

    [icon, mappings[token] || "question"]
  end
end