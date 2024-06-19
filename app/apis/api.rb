class Api
  def fetch
    response = HTTParty.get(Timeframe::Application.config.local["#{self.class.name.underscore}_url"], headers: headers)

    return if response.code != 200

    save_response(response)
  end

  def prepare_response(response)
    JSON.parse(response.body)
  end

  def save_response(response)
    Timeframe::Application.redis.set(storage_key, {last_fetched_at: Time.now.utc, response: prepare_response(response)}.to_json)
  end

  def time_before_unhealthy
    10.minutes
  end

  def headers
    {}
  end

  def storage_key
    APP_VERSION + self.class.name.underscore.to_s
  end

  def value
    @value ||= JSON.parse(Timeframe::Application.redis.get(storage_key) || "{}", symbolize_names: true)
  end

  def data
    value[:response] || {}
  end

  def healthy?
    return false unless last_fetched_at

    last_fetched_at > DateTime.now - time_before_unhealthy
  end

  # :nocov:
  def last_fetched_at
    value[:last_fetched_at].present? ? DateTime.parse(value[:last_fetched_at]) : nil
  end
  # :nocov
end
