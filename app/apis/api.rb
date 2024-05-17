class Api
  def self.fetch
    response = HTTParty.get(Timeframe::Application.config.local["#{storage_key}_url"], headers: headers)

    return if response.code != 200 # TODO: log error responses

    save_response(response)
  end

  def self.save_response(response)
    DaybreakValue.upsert(
      storage_key,
      {
        data: response,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    )
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

  def self.data
    DaybreakValue.get(storage_key)[:data] || {}
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - time_before_unhealthy
  end

  # :nocov:
  def self.last_fetched_at
    DaybreakValue.get(storage_key)[:last_fetched_at]
  end
  # :nocov
end