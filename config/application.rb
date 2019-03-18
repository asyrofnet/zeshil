require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Qisme
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :delete, :put, :patch, :options, :head]
      end
    end

    # Compress response using gzip
    # https://robots.thoughtbot.com/content-compression-with-rack-deflater 
    config.middleware.use Rack::Deflater

    # config.middleware.use "HttpLoggingMiddleware"
    # config.active_job.queue_adapter = :inline
    config.active_job.queue_adapter = :sidekiq

    Raven.configure do |config|
      config.dsn = ENV['SENTRY_DSN']
      config.environments = ['production']
    end
  end
end
