# frozen_string_literal: true

# Devise is only used in cloud mode but must be configured regardless
# since the gem is always loaded.
Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "noreply@timeframe.app")

  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = false

  config.remember_for = 30.days
  config.extend_remember_period = true

  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # Passwordless configuration
  config.mailer = "Devise::Passwordless::Mailer"
  config.passwordless_tokenizer = "MessageEncryptorTokenizer"
  config.passwordless_login_within = 15.minutes
  config.passwordless_expire_old_tokens_on_sign_in = true
end
