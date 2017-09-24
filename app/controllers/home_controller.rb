  class HomeController < ApplicationController
  def index
  end

  def display
    authenticate_user!

    respond_to do |format|
      format.html
      format.json do
        tz = "America/Denver"
        time = DateTime.now.utc.in_time_zone(tz)

        sun_phase = current_user.weather["sun_phase"]
        icon_class, label =
          if (time.strftime("%-H%M").to_i > (sun_phase["sunrise"]["hour"] + sun_phase["sunrise"]["minute"]).to_i) && (time.strftime("%-H%M").to_i < (sun_phase["sunset"]["hour"] + sun_phase["sunset"]["minute"]).to_i)
            ["fa-moon-o", "#{sun_phase["sunset"]["hour"].to_i - 12}:#{sun_phase["sunset"]["minute"]}pm"]
          else
            ["fa-sun-o", "#{sun_phase["sunrise"]["hour"]}:#{sun_phase["sunrise"]["minute"]}am"]
          end

        today_events =
          current_user.calendar_events_for(Time.now.in_time_zone(tz).to_i, Time.now.in_time_zone(tz).end_of_day.utc.to_i).map do |event|
            unless event["all_day"]
              event["time"] = "#{Time.at(event["start_i"]).in_time_zone(tz).strftime('%-l:%M%P')} - #{Time.at(event["end_i"]).in_time_zone(tz).strftime('%-l:%M%P')}"
            end

            event
          end

        tomorrow_events =
          current_user.calendar_events_for(Time.now.in_time_zone(tz).tomorrow.beginning_of_day.to_i, Time.now.in_time_zone(tz).tomorrow.end_of_day.utc.to_i).map do |event|
            unless event["all_day"]
              event["time"] = "#{Time.at(event["start_i"]).in_time_zone(tz).strftime('%-l:%M%P')} - #{Time.at(event["end_i"]).in_time_zone(tz).strftime('%-l:%M%P')}"
            end

            event
          end

        render(json: {
          api_version: 1,
          today_events: {
            all_day: today_events.select { |event| event["all_day"] },
            periodic: today_events.select { |event| !event["all_day"] }
          },
          tomorrow_events: {
            all_day: tomorrow_events.select { |event| event["all_day"] },
            periodic: tomorrow_events.select { |event| !event["all_day"] }
          },
          time: time,
          timestamp: current_user.updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
          tz: tz,
          weather: {
            current_temperature: current_user.weather["current_observation"]["temp_f"].round.to_s + "°",
            summary: current_user.weather["forecast"]["txt_forecast"]["forecastday"].first["fcttext"],
            sun_phase_icon_class: icon_class,
            sun_phase_label: label,
            temperature_range: "#{current_user.weather["forecast"]["simpleforecast"]["forecastday"].first["high"]["fahrenheit"]}° / #{current_user.weather["forecast"]["simpleforecast"]["forecastday"].first["low"]["fahrenheit"]}°",
          }
        })
      end
    end
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
end
