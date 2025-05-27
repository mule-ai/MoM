require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true

  config.cache_store = :null_store

  config.action_controller.raise_on_missing_callback_actions = true

  config.active_record.maintain_test_schema = true

  config.log_level = :debug
end