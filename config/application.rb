require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module MoM
  class Application < Rails::Application
    config.load_defaults 8.0

    config.api_only = false

    config.autoload_lib(ignore: %w(assets tasks proto grpc_server.rb))
  end
end