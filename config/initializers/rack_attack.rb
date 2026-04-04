# frozen_string_literal: true

class Rack::Attack
  # Disable throttling in test environment
  unless Rails.env.test?
    # Throttle by device ID for /d/ routes: 5 requests per minute per device
    throttle("token_displays/device", limit: 5, period: 60) do |req|
      if req.path.start_with?("/d/")
        req.path.split("/")[2]
      end
    end

    # Throttle by IP for /d/ routes: 30 requests per minute per IP
    throttle("token_displays/ip", limit: 30, period: 60) do |req|
      req.ip if req.path.start_with?("/d/")
    end
  end
end
