class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: view_object}
  end

  def mira
    @refresh = true

    # :nocov:
    begin
      render "mira", locals: {view_object: view_object}      
    rescue => e
      Rails.logger.error("listing #{Thread.list.count} threads:")
      Thread.list.each_with_index do |t,i| 
         Rails.logger.error("---- thread #{i}: #{t.inspect}")
         Rails.logger.error(t.backtrace.take(5))
      end

      stats = ActiveRecord::Base.connection_pool.stat
      Rails.logger.error("Connection Pool Stats #{stats.inspect}")

      Rails.logger.error("Render error: " + e.message + e.backtrace.join("\n"))

      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    # :nocov:
  end

  private

  def view_object
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    day_groups =
      (0...5).each_with_object([]).map do |day_index|
        date = current_time + day_index.day

        day_name =
          case day_index
          when 0
            "Today"
          when 1
            "Tomorrow"
          else
            date.strftime("%A")
          end

        {
          day_name: day_name,
          show_daily_events: day_index.zero? ? date.hour <= 19 : true,
          events: CalendarFeed.events_for(
            (day_index.zero? ? current_time : date.beginning_of_day).utc,
            date.end_of_day.utc
          )
        }
      end

   

    # :nocov:
    status_icons = []

    if HomeAssistantApi.healthy?
      status_icons << "box-open" if HomeAssistantApi.package_present?
      status_icons << "garage-open" if HomeAssistantApi.garage_door_open?
      status_icons << "washing-machine" if HomeAssistantApi.washer_needs_attention?
      status_icons << "dryer-heat" if HomeAssistantApi.dryer_needs_attention?
      status_icons << "car-side-bolt" if HomeAssistantApi.car_needs_plugged_in?
      status_icons << "video" if HomeAssistantApi.active_video_call?
    else
      status_icons << "house-circle-exclamation"
    end

    status_icons << "cloud-slash" if !WeatherKitApi.healthy?
    status_icons << "volume-slash" if !SonosApi.healthy?
    status_icons << "microphone-slash" if !BirdnetApi.healthy?

    status_icons_with_labels = []

    HomeAssistantApi.unavailable_door_sensors.each do |door_sensor_name|
      status_icons_with_labels << ["triangle-exclamation", door_sensor_name]
    end
    
    HomeAssistantApi.unlocked_doors.each do |door_name|
      status_icons_with_labels << ["lock-open", door_name]
    end

    HomeAssistantApi.open_doors.each do |door_name|
      status_icons_with_labels << ["door-open", door_name]
    end

    GoogleAccount.all.each do |google_account|
      if !google_account.healthy?
        label = Timeframe::Application.config.local["google_accounts"].find { _1["id"] == google_account.email }&.dig("label")
        status_icons_with_labels << ["calendar-circle-exclamation", label] 
      end
    end

    minutely_weather_minutes = []
    minutely_weather_minutes_icon = nil
    condition = WeatherKitApi.data.dig("forecastNextHour", "summary")&.first.to_h["condition"]
    
    if (WeatherKitApi.healthy? && condition != "clear")
      minutely_weather_minutes_icon = condition == "snow" ? "snowflake" : "raindrops"
      minutely_weather_minutes = WeatherKitApi.data["forecastNextHour"]["minutes"].first(60)
    end
    # :nocov:

    {
      minutely_weather_minutes: minutely_weather_minutes,
      minutely_weather_minutes_icon: minutely_weather_minutes_icon,
      status_icons: status_icons,
      status_icons_with_labels: status_icons_with_labels,
      current_temperature: HomeAssistantApi.feels_like_temperature,
      day_groups: day_groups,
      timestamp: current_time.strftime("%-l:%M %p")
    }
  end
end
