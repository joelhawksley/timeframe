class WeatherService
  def self.call(user)
    user.update(weather:
      HTTParty.get("https://api.darksky.net/forecast/#{Rails.application.secrets.dark_sky_api_key}/#{user.latitude},#{user.longitude}?extend=hourly").as_json
    )
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
