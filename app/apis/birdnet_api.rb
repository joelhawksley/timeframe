class BirdnetApi < Api
  def self.most_unusual_species_trailing_24h
    return {} unless healthy?
    
    data["species"]&.try(:last) || {}
  end
end
