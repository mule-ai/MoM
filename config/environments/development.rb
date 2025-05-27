require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.cache_store = :null_store
  end

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  config.log_level = :debug
  config.log_tags = [ :request_id ]

  config.action_controller.raise_on_missing_callback_actions = true

  # Allow requests from custom hostname
  config.hosts << "mom.butler.ooo"
end