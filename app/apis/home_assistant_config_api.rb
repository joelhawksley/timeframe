class HomeAssistantConfigApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def latitude
    data[:latitude]&.to_s
  end

  def longitude
    data[:longitude]&.to_s
  end
end
