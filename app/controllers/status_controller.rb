class StatusController < ApplicationController
  APIS = [
    HomeAssistantApi,
    HomeAssistantCalendarApi,
    HomeAssistantConfigApi,
    HomeAssistantWeatherApi
  ].freeze

  def index
    render "index", locals: {statuses: api_statuses}
  end

  def show
    render json: {apis: api_statuses}
  end

  private

  def api_statuses
    APIS.map do |api_class|
      api = api_class.new
      {
        name: api_class.name,
        healthy: api.healthy?,
        last_fetched_at: api.last_fetched_at&.iso8601
      }
    end
  end
end
