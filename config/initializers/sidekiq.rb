# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq-status'

# Sidekiq.configure_server do |config|
#   config.redis = { url: ENV['REDISCLOUD_URL'] || 'redis://localhost:6379' }
#   # accepts :expiration (optional)
#   Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes
#   Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
# end

# Sidekiq.configure_client do |config|
#   config.redis = { url: ENV['REDISCLOUD_URL'] || 'redis://localhost:6379' }
#   Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
# end

Sidekiq::Web.class_eval do
  use Rack::Auth::Basic do |email, password|
    user = User.find_by_email(email)
    user&.authenticate(password) && user&.admin?
  end
end
