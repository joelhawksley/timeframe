class StatusController < ApplicationController
  DOMAIN_CHECKS = [
    {name: "States", healthy: :states_healthy?, last_fetched_at: :states_last_fetched_at},
    {name: "Calendars", healthy: :calendars_healthy?, last_fetched_at: :calendars_last_fetched_at},
    {name: "Config", healthy: :config_healthy?, last_fetched_at: :config_last_fetched_at},
    {name: "Weather", healthy: :weather_healthy?, last_fetched_at: :weather_last_fetched_at}
  ].freeze

  def index
    render "index", locals: {statuses: api_statuses}
  end

  def show
    render json: {apis: api_statuses}
  end

  private

  def api_statuses
    api = HomeAssistantApi.new
    DOMAIN_CHECKS.map do |check|
      {
        name: check[:name],
        healthy: api.send(check[:healthy]),
        last_fetched_at: api.send(check[:last_fetched_at])&.iso8601
      }
    end
  end
end
