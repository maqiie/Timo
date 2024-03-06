# require_relative "boot"

# require "rails"
# # Pick the frameworks you want:
# require "active_model/railtie"
# # require "active_job/railtie"
# require "active_record/railtie"
# # require "active_storage/engine"
# require "action_controller/railtie"
# # require "action_mailer/railtie"
# # require "action_mailbox/engine"
# # require "action_text/engine"
# require "action_view/railtie"
# # require "action_cable/engine"
# require "rails/test_unit/railtie"

# # Require the gems listed in Gemfile, including any gems
# # you've limited to :test, :development, or :production.
# Bundler.require(*Rails.groups)

# module Api
#   class Application < Rails::Application
#     # Initialize configuration defaults for originally generated Rails version.
#     config.load_defaults 7.0

#     # Configuration for the application, engines, and railties goes here.
#     #
#     # These settings can be overridden in specific environments using the files
#     # in config/environments, which are processed later.
#     #
#     # config.time_zone = "Central Time (US & Canada)"
#     # config.eager_load_paths << Rails.root.join("extras")

#     # Don't generate system test files.
#     config.generators.system_tests = nil
#   end
# end




require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DeviseTokenAuthTwitter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # config.middleware.use ActionDispatch::Session::CookieStore
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.

    config.generators.system_tests = nil
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # ここからコピペする
    config.session_store :cookie_store, key: '_interslice_session'
    config.middleware.use ActionDispatch::Cookies # Required for all session management
    config.middleware.use ActionDispatch::Session::CookieStore, config.session_options
    config.middleware.use ActionDispatch::Flash


    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
                 :headers => :any,
                 :expose => ['access-token', 'expiry', 'token-type', 'uid', 'client'],
                 :methods => [:get, :post, :options, :delete, :put]
      end
    end
    # ここまで
  end
end

