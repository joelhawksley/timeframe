namespace :fetch do
  task all: :environment do
    User.all.each do |user|
      weather = HTTParty.get("http://api.wunderground.com/api/f79789b09f774c40/forecast/astronomy/conditions/q/#{user.location.delete(" ")}.json").as_json
      user.update(weather: weather, calendar_events: CalendarService.call(user))
    end
  end
end
