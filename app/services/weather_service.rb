# frozen_string_literal: true

class WeatherService
  def self.call
    result = {}

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

    Value.find_or_create_by(key: "weather").update(value: result)

    Log.create(
      globalid: "WeatherService",
      event: "call_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: "WeatherService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def self.healthy?(log = Log.where(globalid: 'WeatherService', event: 'call_success').last)
    return false unless log

    log.created_at > DateTime.now - 1.hour
  end

  def self.calendar_events
    alert = most_important_weather_alert

    out = []

    if alert
      icon =
        if String(alert['event']).include?('Winter')
          'snowflake'
        else
          'warning'
        end

      summary =
        if String(alert['event']).include?('Winter')
          if alert['description'].include?('Additional snow')
            alert['description']
              .tr("\n", ' ')
              .split('Additional snow accumulations')
              .last
              .split('.')
              .first
              .strip
              .gsub(' inches', '"')
          else
            desc = alert['description']
                   .tr("\n", ' ')
                   .split('accumulations between')
                   .last
                   .split('.')
                   .first
                   .strip
                   .gsub(' and ', '-')
                   .gsub(' inches', '"')
                   .gsub(' possible', '')
                   .split(', with')
                   .first
                   .split('"')
                   .first

            "NWS #{alert['event'].split(' ').last}: ~#{desc}\""
          end
        else
          alert['event']
        end

      out << CalendarEvent.new(
        start_i: DateTime.parse(alert['onset']).to_i,
        end_i: DateTime.parse(alert['ends'] || alert['expires']).to_i,
        calendar: '_weather_alerts',
        summary: summary,
        icon: icon
      ).to_h.with_indifferent_access
    end

    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

    [today, today.tomorrow, today + 2.day, today + 3.day].each do |twz|
      noon_i = twz.noon.to_i
      weather_hour = HourlyWeatherService.for(noon_i)

      if weather_hour.present?
        out <<
          CalendarEvent.new(
            id: noon_i,
            start_i: noon_i,
            end_i: noon_i,
            calendar: '_weather_alerts',
            icon: weather_hour['icon_class'],
            summary: "#{weather_hour['temperature'].round}°".html_safe
          ).to_h.with_indifferent_access
      end

      p_i = (twz.noon + 4.hours).to_i
      weather_hour = HourlyWeatherService.for(p_i)

      if weather_hour.present?
        out <<
          CalendarEvent.new(
            id: p_i,
            start_i: p_i,
            end_i: p_i,
            calendar: '_weather_alerts',
            icon: weather_hour['icon_class'],
            summary: "#{weather_hour['temperature'].round}°".html_safe
          ).to_h.with_indifferent_access
      end
    end

    weather.dig('wunderground_forecast', 'sunsetTimeLocal').to_a.each do |sunset_time|
      sunset_i = DateTime.parse(sunset_time).to_i
      weather_hour = HourlyWeatherService.for(sunset_i)

      next unless weather_hour

      out <<
        CalendarEvent.new(
          id: sunset_i,
          start_i: sunset_i,
          end_i: sunset_i,
          calendar: '_weather_alerts',
          icon: weather_hour['icon_class'],
          summary: "#{weather_hour['temperature'].round}°".html_safe
        ).to_h.with_indifferent_access
    end

    weather.dig('wunderground_forecast', 'sunriseTimeLocal').to_a.each do |sunrise_time|
      sunrise_i = DateTime.parse(sunrise_time).to_i
      weather_hour = HourlyWeatherService.for(sunrise_i)

      next unless weather_hour

      out <<
        CalendarEvent.new(
          id: sunrise_i,
          start_i: sunrise_i,
          end_i: sunrise_i,
          calendar: '_weather_alerts',
          icon: weather_hour['icon_class'],
          summary: "#{weather_hour['temperature'].round}°".html_safe
        ).to_h.with_indifferent_access
    end

    precip_windows = []

    HourlyWeatherService.periods.each_with_index do |hour, _index|
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

      if (existing_index = precip_windows.find_index { _1['summary'] == summary && _1['end_i'] == hour['start_i'] })
        precip_windows[existing_index]['end_i'] = hour['end_i']
      else
        precip_windows <<
          CalendarEvent.new(
            id: "#{hour['start_i']}_window",
            start_i: hour['start_i'],
            end_i: hour['end_i'],
            calendar: '_weather_alerts',
            icon: icon,
            summary: summary
          ).to_h.with_indifferent_access
      end
    end

    out.concat(precip_windows)
  end

  def self.most_important_weather_alert
    return nil unless weather.to_h.dig('nws_alerts', 'features').to_a.any?

    alerts = weather['nws_alerts']['features']

    alert_severity_mappings = {
      'Severe' => 0,
      'Moderate' => 1
    }

    alerts
      .reject { |alert| alert.dig('properties', 'urgency') == 'Past' }
      .sort_by { |alert| alert_severity_mappings[alert['properties']['severity']] }
      .uniq { |alert| alert['properties']['event'] }
      .reject { |alert| alert['properties']['areaDesc'].to_s.include?('OZONE ACTION DAY') }
      .first['properties']
  end

  def self.weather
    @weather ||= Value.weather
  end
end
