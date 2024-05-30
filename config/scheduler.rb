scheduler = Rufus::Scheduler.new

if ENV["RUN_BG"]
  scheduler.every "1s" do
    SonosApi.fetch
  end

  scheduler.every "1s" do
    HomeAssistantApi.fetch
  end

  scheduler.every "1m", first: :now do
    WeatherKitApi.fetch
  end

  scheduler.every "1m", first: :now do
    ActiveRecord::Base.connection_pool.with_connection do
      GoogleAccount.all.each(&:fetch)
    end
  end

  scheduler.every "5m", first: :now do
    BirdnetApi.fetch
  end

  scheduler.every "5m", first: :now do
    DogParkApi.fetch
  end
end

scheduler.join