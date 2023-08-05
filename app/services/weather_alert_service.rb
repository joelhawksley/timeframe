class WeatherAlertService
  def self.load
    Value.find_or_create_by(key: "weather_alerts").value || {}
  end

  def self.fetch
    result[:response] = JSON.parse(
      HTTParty.get(
        "https://api.weather.gov/alerts/active/zone/#{ENV['NWS_ZONE']}",
        {headers: {"User-Agent" => "joel@hawksley.org"}}
      )
    )

    result[:last_fetched_at] = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s

    Value.find_or_create_by(key: "weather_alerts").update(value: result)
  end

  def self.weather_alert_calendar_event
    return nil unless load.dig('response', 'features').to_a.any?

    alerts = load['response']['features']

    alert_severity_mappings = {
      'Severe' => 0,
      'Moderate' => 1
    }

    alert = alerts
      .reject { |alert| alert.dig('properties', 'urgency') == 'Past' }
      .sort_by { |alert| alert_severity_mappings[alert['properties']['severity']] }
      .uniq { |alert| alert['properties']['event'] }
      .reject { |alert| alert['properties']['areaDesc'].to_s.include?('OZONE ACTION DAY') }
      .first['properties']


    return unless alert

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

    CalendarEvent.new(
      start_i: DateTime.parse(alert['onset']).to_i,
      end_i: DateTime.parse(alert['ends'] || alert['expires']).to_i,
      calendar: '_weather_alerts',
      summary: summary,
      icon: icon
    )
  end
end