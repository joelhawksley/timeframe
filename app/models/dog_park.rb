# frozen_string_literal: true

class DogPark
  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 10.minutes
  end

  def self.data
    MemoryValue.get(:dogpark)[:data] || {}
  end

  def self.last_fetched_at
    MemoryValue.get(:dogpark)[:last_fetched_at]
  end

  def self.open?
    return false unless data.present?

    data.downcase.include?("mesa is open")
  end

  def self.fetch
    response = HTTParty.get(
      Timeframe::Application.config.local["dog_park_url"],
      headers: { # from https://github.com/lwthiker/curl-impersonate/blob/822dbefe42e077fb9f3f16eaf0eca24944e5aadc/chrome/curl_chrome116
        "sec-ch-ua" => '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        "sec-ch-ua-mobile" => "?0",
        "sec-ch-ua-platform" => '"Windows"',
        "Upgrade-Insecure-Requests" => "1",
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Sec-Fetch-Site" => "none",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-User" => "?1",
        "Sec-Fetch-Dest" => "document",
        "Accept-Encoding" => "gzip, deflate, br",
        "Accept-Language" => "en-US,en;q=0.9"
      }
    )

    return if response["status"] == "error"

    MemoryValue.upsert(:dogpark,
      {
        data: response,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      })
  end
end
