# frozen_string_literal: true

class TimeframeConfig < Anyway::Config
  config_name :timeframe

  attr_config apple_developer_team_id: nil,
    apple_developer_service_id: nil,
    apple_developer_key_id: nil,
    apple_developer_private_key: nil

  def weatherkit?
    apple_developer_team_id.present?
  end
end
