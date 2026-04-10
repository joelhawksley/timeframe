# frozen_string_literal: true

if ENV["GOOGLE_CLIENT_ID"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      ENV.fetch("GOOGLE_CLIENT_ID"),
      ENV.fetch("GOOGLE_CLIENT_SECRET"),
      scope: "email,https://www.googleapis.com/auth/calendar.readonly",
      access_type: "offline",
      prompt: "consent"
  end

  OmniAuth.config.allowed_request_methods = [:post]
  OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
end
