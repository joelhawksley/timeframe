class WeatherAlertService
  def self.load
    Current.weather_alerts ||=
      Value.find_or_create_by(key: "weather_alerts").value || {}
  end

  def self.fetch
    result = {
      response:
        JSON.parse(
          HTTParty.get(
            "https://api.weather.gov/alerts/active/zone/#{ENV['NWS_ZONE']}",
            {headers: {"User-Agent" => "joel@hawksley.org"}}
          )
        )
    }

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
      .reject { |alert| alert['properties']['areaDesc'].to_s.include?('OZONE ACTION DAY') }
      .first['properties']

    return unless alert

    summary =
      if alert['event'].include?('Special Weather Statement')
        alert["parameters"]["NWSheadline"][0]
      else
        alert['event']
      end

    CalendarEvent.new(
      starts_at: DateTime.parse(alert['onset']).to_i,
      ends_at: DateTime.parse(alert['ends'] || alert['expires']).to_i,
      summary: summary,
      icon: 'warning'
    )
  end
end