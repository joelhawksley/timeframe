# frozen_string_literal: true

namespace :fetch do
  task tokens: :environment do
    GoogleAccount.refresh_all
  end

  task weather: :environment do
    WundergroundService.call
    HourlyWeatherService.fetch
    WeatherAlertService.fetch
  end

  task google: :environment do
    GoogleService.call
  end
end
