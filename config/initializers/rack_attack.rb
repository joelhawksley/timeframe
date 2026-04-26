# frozen_string_literal: true

class Rack::Attack
  unless Rails.env.test?
    throttle("token_devices/device", limit: 5, period: 60) do |req|
      if req.path.start_with?("/d/")
        req.path.split("/")[2]
      end
    end

    throttle("token_devices/ip", limit: 30, period: 60) do |req|
      req.ip if req.path.start_with?("/d/")
    end

    throttle("pairing/ip", limit: 5, period: 60) do |req|
      if req.post? && req.path.include?("/devices") && req.path.end_with?("/devices", "/repair")
        req.ip
      end
    end
  end
end
