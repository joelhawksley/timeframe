class Api
  def self.fetch
    response = HTTParty.get(Timeframe::Application.config.local["#{storage_key}_url"], headers: headers)

    return if response.code != 200 # TODO: log error responses

    save_response(response)
  end

  def self.prepare_response(response)
    JSON.parse(response.body)
  end

  def self.save_response(response)
    ApiResponse.create(name: storage_key, response: prepare_response(response))
  end

  def self.time_before_unhealthy
    10.minutes
  end

  def self.headers
    {}
  end

  def self.storage_key
    name.underscore.to_s
  end

  def self.latest_api_response
    ApiResponse.where(name: storage_key).last
  end

  def self.data
    latest_api_response&.response || {}
  end

  def self.healthy?
    return false unless last_fetched_at

    last_fetched_at > DateTime.now - time_before_unhealthy
  end

  # :nocov:
  def self.last_fetched_at
    latest_api_response&.created_at
  end
  # :nocov
end