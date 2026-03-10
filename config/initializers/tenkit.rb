Tenkit.configure do |c|
  local_config = Timeframe::Application.config.local

  c.team_id = local_config["apple_developer_team_id"]
  c.service_id = local_config["apple_developer_service_id"]
  c.key_id = local_config["apple_developer_key_id"]
  key = local_config["apple_developer_private_key"].to_s
  c.key = key.gsub("\\n", "\n")
end
