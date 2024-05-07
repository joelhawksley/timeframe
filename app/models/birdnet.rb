class Birdnet < ApiModel
  def self.config_url_key
    "birdnet_url"
  end

  def self.most_unusual_species_trailing_24h
    data["species"]&.try(:last) || {}
  end
end
