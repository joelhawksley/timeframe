class WeatherService
  def self.call(user)
    user.update(weather:
      HTTParty.get("http://api.wunderground.com/api/f79789b09f774c40/forecast/astronomy/conditions/hourly/q/#{user.location.delete(" ")}.json").as_json
    )
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
