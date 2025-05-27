require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [ :request_id ]

  config.cache_store = :memory_store

  config.active_record.dump_schema_after_migration = false

  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") {
    SecureRandom.hex(64)
  }

  # Allow requests from custom hostname
  config.hosts << "mom.butler.ooo"
end