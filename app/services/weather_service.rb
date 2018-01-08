class WeatherService
  def self.call(user)
    user.update(weather:
      HTTParty.get("http://api.wunderground.com/api/f79789b09f774c40/forecast/astronomy/conditions/hourly/q/#{user.location.delete(" ")}.json").as_json
    )
  end
end
