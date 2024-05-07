class ApiModel
  def self.fetch
    response = HTTParty.get(Timeframe::Application.config.local["#{storage_key}_url"], headers: headers)

    return if response["status"] == "error" # TODO: log error responses

    MemoryValue.upsert(
      storage_key,
      {
        data: response,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    )
  end

  def self.headers
    {}
  end

  def self.storage_key
    name.underscore.to_sym
  end

  def self.data
    MemoryValue.get(storage_key)[:data] || {}
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 10.minutes
  end

  # :nocov:
  def self.last_fetched_at
    MemoryValue.get(storage_key)[:last_fetched_at]
  end
  # :nocov
end