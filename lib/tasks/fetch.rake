# frozen_string_literal: true

namespace :fetch do
  task all: :environment do
    GoogleAccount.all.each(&:refresh!)
    Log.create(globalid: "Application/Timeframe", event: "fetch", message: "")
    WeatherService.call
    GoogleService.call
  end
end
