class Birdnet < ApiModel
  def self.most_unusual_species_trailing_24h
    data["species"]&.try(:last) || {}
  end
end
