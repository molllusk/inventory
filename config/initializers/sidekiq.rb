# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDISCLOUD_URL'] || 'redis://localhost:6379' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDISCLOUD_URL'] || 'redis://localhost:6379' }
end

Sidekiq::Web.class_eval do
  use Rack::Auth::Basic do |email, password|
    user = User.find_by_email(email)
    user&.authenticate(password) && user&.admin?
  end
end
