class HourlyWeatherService
  def self.for(local_time_i)
    load["periods"].find { (_1['start_i'].._1['end_i']).cover?(local_time_i) }
  end

  def self.periods
    load["periods"]
  end

  def self.load
    Value.find_or_create_by(key: "hourly_weather").value || {}
  end

  def self.calendar_events
    out = []

    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

    [today, today.tomorrow, today + 2.day, today + 3.day].each do |twz|
      [
        (twz.noon - 4.hours).to_i,
        twz.noon.to_i,
        (twz.noon + 4.hours).to_i,
        (twz.noon + 8.hours).to_i
      ].each do |hour_i|
        weather_hour = HourlyWeatherService.for(hour_i)

        if weather_hour.present?
          out <<
            CalendarEvent.new(
              id: hour_i,
              start_i: hour_i,
              end_i: hour_i,
              calendar: '_weather_alerts',
              icon: weather_hour['icon_class'],
              summary: "#{weather_hour['temperature'].round}°".html_safe
            )
        end
      end
    end

    out
  end

  def self.precip_calendar_events
    events = []

    periods.each do |hour|
      next unless hour['icon'].split(',').length == 2

      summary, icon =
        case hour['icon'].split(',').first
        when 'snow', 'blizzard'
          %w[Snow snowflake]
        when 'rain', 'rain_showers', 'tsra', 'tsra_sct', 'tsra_hi'
          %w[Rain raindrops]
        when 'smoke'
          %w[Smoke smoke]
        end

      next unless summary

      if (existing_index = events.find_index { _1['summary'] == summary && _1['end_i'] == hour['start_i'] })
        events[existing_index]['end_i'] = hour['end_i']
      else
        events <<
          CalendarEvent.new(
            id: "#{hour['start_i']}_window",
            start_i: hour['start_i'],
            end_i: hour['end_i'],
            calendar: '_weather_alerts',
            icon: icon,
            summary: summary
          )
      end
    end

    events
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