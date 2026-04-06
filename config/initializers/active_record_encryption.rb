# frozen_string_literal: true

# Active Record Encryption keys.
# In production/cloud, these MUST be set via environment variables.
# In single-tenant mode, they are auto-generated deterministically from the secret_key_base.
if Timeframe::Application.multi_tenant?
  Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
  Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
else
  base = Rails.application.config.secret_key_base
  Rails.application.config.active_record.encryption.primary_key = Digest::SHA256.hexdigest("#{base}-primary")[0, 32]
  Rails.application.config.active_record.encryption.deterministic_key = Digest::SHA256.hexdigest("#{base}-deterministic")[0, 32]
  Rails.application.config.active_record.encryption.key_derivation_salt = Digest::SHA256.hexdigest("#{base}-salt")[0, 32]
end
