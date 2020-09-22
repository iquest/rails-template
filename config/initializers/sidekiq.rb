# frozen_string_literal: true

if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.redis = { db: ENV['SIDEKIQ_DB'].presence || '1' }
  end

  Sidekiq.configure_client do |config|
    config.redis = { db: ENV['SIDEKIQ_DB'].presence || '1' }
  end
end
