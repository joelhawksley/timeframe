# frozen_string_literal: true

base = Rails.application.config.secret_key_base
Rails.application.config.active_record.encryption.primary_key = Digest::SHA256.hexdigest("#{base}-primary")[0, 32]
Rails.application.config.active_record.encryption.deterministic_key = Digest::SHA256.hexdigest("#{base}-deterministic")[0, 32]
Rails.application.config.active_record.encryption.key_derivation_salt = Digest::SHA256.hexdigest("#{base}-salt")[0, 32]
