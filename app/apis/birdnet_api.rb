class BirdnetApi < Api
  def most_unusual_species_trailing_24h
    return {} unless healthy?

    data["species"]&.try(:last) || {}
  end

  def time_before_unhealthy
    30.minutes
  end
end
