class Birdnet
  def self.fetch
    response = HTTParty.get(Timeframe::Application.config.local["birdnet_url"])

    return if response["status"] == "error"

    MemoryValue.upsert(
      :birdnet,
      {
        data: response,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    )
  end

  def self.data
    MemoryValue.get(:birdnet)[:data] || {}
  end

  def self.most_unusual_species_trailing_24h
    data["species"]&.try(:last) || {}
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 10.minutes
  end

  # :nocov:
  def self.last_fetched_at
    MemoryValue.get(:birdnet)[:last_fetched_at]
  end
  # :nocov
end
