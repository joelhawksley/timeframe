# frozen_string_literal: true

module ApplicationHelper
  def baby_age_string
    day_count = Date.today - Date.parse(app_config["birthdate"])
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

    if remainder > 0
      "#{week_count}w#{remainder}d"
    else
      "#{week_count}w"
    end
  end

  def tz
    app_config["timezone"]
  end

  def app_config
    @app_config ||= YAML.load_file(Rails.root.join("config.yml"))
  end

  ALERT_SEVERITY_MAPPINGS = {
    'Severe' => 0,
    'Moderate' => 1
  }

  def weather
    @weather ||= Value.weather
  end

  def sorted_calendar_events_array
    @sorted_calendar_events_array ||= Value.sorted_calendar_events_array
  end

  def most_important_weather_alert
    return nil unless weather.to_h.dig('nws_alerts', 'features').to_a.any?

    alerts = weather['nws_alerts']['features']

    alerts
      .reject { |alert| alert.dig('properties', 'urgency') == 'Past' }
      .sort_by { |alert| ALERT_SEVERITY_MAPPINGS[alert['properties']['severity']] }
      .uniq { |alert| alert['properties']['event'] }
      .reject { |alert| alert['properties']['areaDesc'].to_s.include?('OZONE ACTION DAY') }
      .first['properties']
  end

  # convert weather alerts to be timeline events;
  # they are timely, after all!
  def weather_calendar_events(_now = DateTime.now)
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

      out << {
        'start_i' => DateTime.parse(alert['onset']).to_i,
        'end_i' => DateTime.parse(alert['ends'] || alert['expires']).to_i,
        'calendar' => '_weather_alerts',
        'summary' => summary,
        'icon' => icon
      }
    end

    [Date.today.in_time_zone(tz), Date.today.in_time_zone(tz).tomorrow, Date.today.in_time_zone(tz) + 2.day,
     Date.today.in_time_zone(tz) + 3.day].each do |twz|
      noon_i = twz.noon.to_i
      weather_hour = weather['nws_hourly'].find { (_1['start_i'].._1['end_i']).cover?(noon_i) }

      if weather_hour.present?
        out <<
          {
            'id' => noon_i,
            'start_i' => noon_i,
            'end_i' => noon_i,
            'calendar' => '_weather_alerts',
            'icon' => weather_hour['icon_class'],
            'summary' => "#{weather_hour['temperature'].round}°".html_safe
          }
      end

      p_i = (twz.noon + 4.hours).to_i
      weather_hour = weather['nws_hourly'].find { (_1['start_i'].._1['end_i']).cover?(p_i) }

      if weather_hour.present?
        out <<
          {
            'id' => p_i,
            'start_i' => p_i,
            'end_i' => p_i,
            'calendar' => '_weather_alerts',
            'icon' => weather_hour['icon_class'],
            'summary' => "#{weather_hour['temperature'].round}°".html_safe
          }
      end
    end

    weather.dig('wunderground_forecast', 'sunsetTimeLocal').to_a.each do |sunset_time|
      sunset_i = DateTime.parse(sunset_time).to_i
      weather_hour = weather['nws_hourly'].find { (_1['start_i'].._1['end_i']).cover?(sunset_i) }

      next unless weather_hour

      out <<
        {
          'id' => sunset_i,
          'start_i' => sunset_i,
          'end_i' => sunset_i,
          'calendar' => '_weather_alerts',
          'icon' => weather_hour['icon_class'],
          'summary' => "#{weather_hour['temperature'].round}°".html_safe
        }
    end

    weather.dig('wunderground_forecast', 'sunriseTimeLocal').to_a.each do |sunrise_time|
      sunrise_i = DateTime.parse(sunrise_time).to_i
      weather_hour = weather['nws_hourly'].find { (_1['start_i'].._1['end_i']).cover?(sunrise_i) }

      next unless weather_hour

      out <<
        {
          'id' => sunrise_i,
          'start_i' => sunrise_i,
          'end_i' => sunrise_i,
          'calendar' => '_weather_alerts',
          'icon' => weather_hour['icon_class'],
          'summary' => "#{weather_hour['temperature'].round}°".html_safe
        }
    end

    precip_windows = []

    weather['nws_hourly'].each_with_index do |hour, _index|
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
          {
            'id' => "#{hour['start_i']}_window",
            'start_i' => hour['start_i'],
            'end_i' => hour['end_i'],
            'calendar' => '_weather_alerts',
            'icon' => icon,
            'summary' => summary
          }
      end
    end

    out.concat(precip_windows)
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def calendar_events_for(
    beginning_i = DateTime.now.in_time_zone(tz).tomorrow.beginning_of_day.to_i,
    ending_i = DateTime.now.in_time_zone(tz).tomorrow.end_of_day.to_i
  )

    filtered_events = (weather_calendar_events + sorted_calendar_events_array).select do |event|
      (event['start_i']..event['end_i']).overlaps?(beginning_i...ending_i)
    end

    parsed_events = filtered_events.map do |event|
      event['time'] = EventTimeService.call(event['start_i'], event['end_i'], tz)
      event
    end

    # Merge duplicate events, merging the letter with a custom rule if so
    parsed_events
      .group_by { _1['id'] }
      .map do |_k, v|
        if v.length > 1
          letters = v.map { |iv| iv['letter'] }
          letter =
            if letters.uniq.length == 1
              letters[0]
            elsif letters.include?('+')
              '+'
            else
              letters[0]
            end

          out = v[0]
          out['letter'] = letter
          out
        else
          v[0]
        end
      end.sort_by { |event| event['start_i'] }
  end

  def render_json_payload(at = DateTime.now)
    current_time = at.utc.in_time_zone(tz)

    day_groups =
      (0...5).each_with_object([]) do |day_index, memo|
        date = Time.now.in_time_zone(tz) + day_index.day

        start_i =
          case day_index
          when 0
            # Add 180 seconds so that events ending at the top of the hour are not shown for the following half hour
            Time.now.in_time_zone(tz).utc.to_i + 180
          else
            date.beginning_of_day.utc.to_i
          end

        end_i = date.end_of_day.utc.to_i

        day_name = date.strftime('%A')

        events = calendar_events_for(start_i, end_i)
        all_day_events = events.select { |event| event['all_day'] }

        mappings = [
          "Birthdays",
          "Us",
          "Caitlin",
          "Caitlin Exercise Log",
          "Captain",
          "Dinner",
          "Friends & Family",
          "HelloFresh",
          "Holidays in United States",
          "Home",
          "Joel",
          "Joel Health",
          "On Call Schedule for joelhawksley",
          "joelhawksley@github.com",
          "Work",
        ]

        groupings = all_day_events.group_by { |event| event['calendar'] }

        groupings.transform_values! do |arr|
          arr.sort! do |x, y|
            # if this result is 1 means x should come later relative to y
            # if this result is -1 means x should come earlier relative to y
            # if this result is 0 means both are same so position doesn't matter
            if x['calendar'] != 'Dinner'
              # if this result is 1 means x should come later relative to y
              # if this result is -1 means x should come earlier relative to y
              # if this result is 0 means both are same so position doesn't matter
              if !x['multi_day'] && y['multi_day']
                -1
              elsif x['multi_day'] && !y['multi_day']
                1
              else
                0
              end
            # elsif x['summary'].starts_with?('Dinner')
            #   1
            # elsif x['summary'].starts_with?('Lunch') && y['summary'].starts_with?('Dinner')
            #   -1
            # elsif x['summary'].starts_with?('Lunch') && y['summary'].starts_with?('Breakfast')
            #   1
            # elsif x['summary'].starts_with?('Breakfast')
            #   -1
            else
              0
            end
          end
        end

        pairs = groupings.flat_map do |calendar, events|
          events.map do |event|
            [calendar, event]
          end
        end

        pairs.sort_by! do |pair|
          mappings.index(pair[0])
        end.map!(&:last)

        all_day_events.sort! do |x, y|
          # if this result is 1 means x should come later relative to y
          # if this result is -1 means x should come earlier relative to y
          # if this result is 0 means both are same so position doesn't matter
          if !x['multi_day'] && y['multi_day']
            -1
          elsif x['multi_day'] && !y['multi_day']
            1
          else
            0
          end
        end

        out = {
          day_index: day_index,
          day_name: day_name,
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: {
            all_day: pairs,
            periodic: events.reject { |event| event['all_day'] }
          }
        }

        high = weather['wunderground_forecast']['calendarDayTemperatureMax'][day_index]
        low = weather['wunderground_forecast']['calendarDayTemperatureMin'][day_index]

        out[:precip_label] = if weather['wunderground_forecast']['qpfSnow'][day_index] > 0
                               " <i class='fa-regular fa-snowflake'></i> #{weather['wunderground_forecast']['qpfSnow'][day_index].round}\""
                             else
                               " #{weather['wunderground_forecast']['qpf'][day_index].round}%"
                             end
        out[:temperature_range] = "&#8593;#{high} &#8595;#{low}".html_safe
        out[:precip_probability] = weather['wunderground_forecast']['qpf'][day_index]

        memo << out
      end

    current_nws_hour =
      weather['nws_hourly']
      .find do
        (_1['start_i'].._1['end_i'])
      .cover?(DateTime.now.utc.in_time_zone(tz).to_i)
      end
    
    out =
      {
        current_temperature: "#{current_nws_hour['temperature']}°",
        day_groups: day_groups,
        timestamp: current_time.strftime('%-l:%M %p')
      }

    out
  end
end
