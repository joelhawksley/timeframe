  class HomeController < ApplicationController
  def index
  end

  def display
    authenticate_user!

    respond_to do |format|
      format.html
      format.json do
        render_json_payload(current_user)
      end
    end
  end

  def display_from_token
    render_json_payload(User.find_by(token: params[:token]))
  end

  def redirect
    authenticate_user!

    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
      access_type: 'offline',
      redirect_uri: callback_url
    })

    redirect_to(client.authorization_uri.to_s)
  end

  def callback
    authenticate_user!

    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      access_type: 'offline',
      redirect_uri: callback_url,
      code: params[:code]
    })

    response = client.fetch_access_token!

    current_user.update(google_authorization: response)

    redirect_to(root_path, flash: { notice: 'Google Account connected' })
  end

  private

  def render_json_payload(user)
    tz = "America/Denver"
    time = DateTime.now.utc.in_time_zone(tz)

    sun_phase = user.weather["sun_phase"]
    icon_class, label =
      if (time.strftime("%-H%M").to_i > (sun_phase["sunrise"]["hour"] + sun_phase["sunrise"]["minute"]).to_i) && (time.strftime("%-H%M").to_i < (sun_phase["sunset"]["hour"] + sun_phase["sunset"]["minute"]).to_i)
        ["fa-moon-o", "#{sun_phase["sunset"]["hour"].to_i - 12}:#{sun_phase["sunset"]["minute"]}pm"]
      else
        ["fa-sun-o", "#{sun_phase["sunrise"]["hour"]}:#{sun_phase["sunrise"]["minute"]}am"]
      end

    today_events =
      user.calendar_events_for(Time.now.in_time_zone(tz).to_i, Time.now.in_time_zone(tz).end_of_day.utc.to_i).map do |event|
        event["time"] = time_for_event(event, tz)
        event
      end

    tomorrow_events =
      user.calendar_events_for(Time.now.in_time_zone(tz).tomorrow.beginning_of_day.to_i, Time.now.in_time_zone(tz).tomorrow.end_of_day.utc.to_i).map do |event|
        event["time"] = time_for_event(event, tz)
        event
      end

    render(json: {
      api_version: 2,
      today_events: {
        all_day: today_events.select { |event| event["all_day"] },
        periodic: today_events.select { |event| !event["all_day"] }
      },
      tomorrow_events: {
        all_day: tomorrow_events.select { |event| event["all_day"] },
        periodic: tomorrow_events.select { |event| !event["all_day"] }
      },
      time: time,
      timestamp: user.updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
      tz: tz,
      weather: {
        current_temperature: user.weather["current_observation"]["temp_f"].round.to_s + "°",
        summary: user.weather["forecast"]["txt_forecast"]["forecastday"].first["fcttext"],
        sun_phase_icon_class: icon_class,
        sun_phase_label: label,
        today_temperature_range: "#{user.weather["forecast"]["simpleforecast"]["forecastday"].first["high"]["fahrenheit"]}° / #{user.weather["forecast"]["simpleforecast"]["forecastday"].first["low"]["fahrenheit"]}°",
        tomorrow_temperature_range: "#{user.weather["forecast"]["simpleforecast"]["forecastday"][1]["high"]["fahrenheit"]}° / #{user.weather["forecast"]["simpleforecast"]["forecastday"][1]["low"]["fahrenheit"]}°",
      }
    })
  end

  def time_for_event(event, tz)
    start = Time.at(event["start_i"]).in_time_zone(tz)
    endtime = Time.at(event["end_i"]).in_time_zone(tz)

    start_label = start.min > 0 ? start.strftime('%-l:%M') : start.strftime('%-l')
    end_label = endtime.min > 0 ? endtime.strftime('%-l:%M%P') : endtime.strftime('%-l%P')
    start_suffix = start.strftime('%P') == endtime.strftime('%P') ? '' : start.strftime('%P')

    "#{start_label}#{start_suffix} - #{end_label}"
  end
end
