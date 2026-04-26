# frozen_string_literal: true

Dummy::Application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_record.encryption.primary_key = "test-primary-key-that-is-long-enough"
  config.active_record.encryption.deterministic_key = "test-deterministic-key-long-enough"
  config.active_record.encryption.key_derivation_salt = "test-key-derivation-salt"
end
