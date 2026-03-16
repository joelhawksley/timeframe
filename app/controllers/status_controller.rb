class StatusController < ApplicationController
  DOMAIN_CHECKS = [
    {name: "States", healthy: :states_healthy?, last_fetched_at: :states_last_fetched_at},
    {name: "Calendars", healthy: :calendars_healthy?, last_fetched_at: :calendars_last_fetched_at},
    {name: "Config", healthy: :config_healthy?, last_fetched_at: :config_last_fetched_at},
    {name: "Weather", healthy: :weather_healthy?, last_fetched_at: :weather_last_fetched_at}
  ].freeze

  def index
    api = HomeAssistantApi.new

    render "index", locals: {
      statuses: api_statuses(api),
      config_data: api.config_data,
      states: api.data,
      calendar_events: api.calendar_events,
      hourly_forecast: api.hourly_forecast,
      daily_forecast: api.daily_forecast,
      top_left: api.top_left,
      top_right: api.top_right,
      weather_status: api.weather_status,
      now_playing: api.now_playing,
      time_zone: api.time_zone
    }
  end

  def show
    render json: {apis: api_statuses}
  end

  private

  def api_statuses(api = HomeAssistantApi.new)
    DOMAIN_CHECKS.map do |check|
      {
        name: check[:name],
        healthy: api.send(check[:healthy]),
        last_fetched_at: api.send(check[:last_fetched_at])&.iso8601
      }
    end
  end
end
