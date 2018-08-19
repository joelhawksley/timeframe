class AirService
  def self.call(user)
    response = HTTParty.get("http://feeds.enviroflash.info/cap/33.xml")

    if response["alert"]["info"]["headline"].include?("no air quality alerts")
      user.update(air: "")
    else
      user.update(air: response["alert"]["info"]["headline"])
    end
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
