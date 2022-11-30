# frozen_string_literal: true

class WeatherService
  def self.call(user)
    user.update(weather:
      HTTParty.get("https://api.darksky.net/forecast/#{ENV["DARK_SKY_API_KEY"]}/39.9147082,-105.0220883?extend=hourly").as_json)
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
