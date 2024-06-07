class Api
  def fetch
    response = HTTParty.get(Timeframe::Application.config.local["#{storage_key}_url"], headers: headers)

    return if response.code != 200 # TODO: log error responses

    save_response(response)
  end

  def prepare_response(response)
    JSON.parse(response.body)
  end

  def save_response(response)
    ApiResponse.create(name: storage_key, response: prepare_response(response))
  end

  def time_before_unhealthy
    10.minutes
  end

  def headers
    {}
  end

  def storage_key
    self.class.name.underscore.to_s
  end

  def latest_api_response
    @latest_api_response ||= ApiResponse.where(name: storage_key).last
  end

  def data
    @data ||=
      begin
        latest_api_response&.response || {}
      end
  end

  def healthy?
    return false unless last_fetched_at

    last_fetched_at > DateTime.now - time_before_unhealthy
  end

  # :nocov:
  def last_fetched_at
    latest_api_response&.created_at
  end
  # :nocov
end