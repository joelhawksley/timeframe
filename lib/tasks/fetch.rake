# frozen_string_literal: true

namespace :fetch do
  task tokens: :environment do
    Log.create(globalid: "Application/Timeframe", event: "fetch_tokens", message: "")
    GoogleAccount.refresh_all
  end

  task weather: :environment do
    Log.create(globalid: "Application/Timeframe", event: "fetch_weather", message: "")
    WeatherService.call
  end

  task google: :environment do
    Log.create(globalid: "Application/Timeframe", event: "fetch_google", message: "")
    GoogleService.call
  end
end
