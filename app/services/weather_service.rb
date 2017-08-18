class WeatherService
  def self.call(user)
    HTTParty.get("http://api.wunderground.com/api/f79789b09f774c40/forecast/astronomy/conditions/q/#{user.location.delete(" ")}.json").as_json
  end
end
