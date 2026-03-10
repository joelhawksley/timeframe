class WeatherKitApi < Api
  def initialize(home_assistant_config_api: HomeAssistantConfigApi.new)
    @home_assistant_config_api = home_assistant_config_api
  end

  def fetch
    return unless Tenkit.config&.team_id.present?

    client = Tenkit::Client.new
    hash = client.weather(
      @home_assistant_config_api.latitude,
      @home_assistant_config_api.longitude,
      data_sets: [
        :forecast_next_hour
      ]
    ).raw

    save_response(hash)
  end

  def prepare_response(response)
    response
  end
end
