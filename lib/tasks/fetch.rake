# frozen_string_literal: true

namespace :fetch do
  task all: :environment do
    Log.create(globalid: "Application/Timeframe", event: "fetch", message: "")
    GoogleAccount.all.each(&:refresh!)
    WeatherService.call
    GoogleService.call
  end
end
