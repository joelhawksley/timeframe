# frozen_string_literal: true

namespace :fetch do
  task tokens: :environment do
    GoogleAccount.refresh_all
  end

  task weather: :environment do
    WeatherService.call
    HourlyWeatherService.fetch
  end

  task google: :environment do
    GoogleService.call
  end
end
