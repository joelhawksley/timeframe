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
      Rails.logger.error("Render error: " + e.message + e.backtrace.join("\n"))

      render "error", locals: {klass: e.class.to_s, message: e.message}
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

    if DogParkApi.healthy? && !DogParkApi.open?
      status_icons << "location-pin-lock"
    else
      status_icons << "bone-break"
    end

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
      status_icons_with_labels << ["calendar-circle-exclamation", google_account.email.truncate(10)] if !google_account.healthy?
    end
    # :nocov:

    {
      status_icons: status_icons,
      status_icons_with_labels: status_icons_with_labels,
      current_temperature: HomeAssistantApi.feels_like_temperature,
      day_groups: day_groups,
      timestamp: current_time.strftime("%-l:%M %p")
    }
  end
end
