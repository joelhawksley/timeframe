# frozen_string_literal: true

# :nocov:
Rails.application.config.after_initialize do
  config = TimeframeConfig.new
  if config.weatherkit?
    Tenkit.configure do |c|
      c.team_id = config.apple_developer_team_id
      c.service_id = config.apple_developer_service_id
      c.key_id = config.apple_developer_key_id
      c.key = config.apple_developer_private_key
    end
  end
end
# :nocov:
