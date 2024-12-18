class HomeAssistantLightningApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def fetch
    start_time = (Time.now - 30.minutes).utc.iso8601
    end_time = Time.now.utc.iso8601

    res = HTTParty.get(
      "#{url}#{start_time}?filter_entity_id=#{@config["home_assistant"]["lightning_distance_sensor_entity_id"]}" \
      "&end_time=#{end_time}",
      headers: headers
    )

    save_response(res)
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def distance
    this_data = data.flatten
    return nil if this_data.empty?

    value = this_data.reject { ["unknown", "unavailable"].include?(_1[:state]) }.map { _1[:state].to_i }.min

    "#{value}mi" if value
  end
end
