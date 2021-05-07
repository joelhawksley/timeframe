# frozen_string_literal: true

class WeatherService
  def self.call(user)
    user.update(weather:
      HTTParty.get("https://api.darksky.net/forecast/#{ENV['DARK_SKY_API_KEY']}/#{user.latitude},#{user.longitude}?extend=hourly").as_json)
  rescue StandardError => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
