# frozen_string_literal: true

if defined?(Raven)
  Raven.configure do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
    config.environments = ["production"]
    revision_file = Rails.root.join("REVISION")
    config.release = File.read(revision_file).strip if File.exist?(revision_file)
    config.async = ->(event) { SentryJob.perform_later(event) }
  end

  raven_tags = {}.tap do |h|
    h[:heroku_app_name] = ENV["HEROKU_APP_NAME"] if ENV["HEROKU_APP_NAME"]
  end

  Raven.tags_context(raven_tags)
end
