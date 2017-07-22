namespace :fetch do
  task all: :environment do
    User.all.each do |user|
      response = Weather.lookup_by_location(user.location, Weather::Units::FAHRENHEIT)
      user.update(weather: response.as_json)
    end
  end
end
