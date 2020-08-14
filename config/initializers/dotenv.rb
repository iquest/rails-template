# frozen_string_literal: true

# Dotenv.require_keys("SERVICE_APP_ID", "SERVICE_KEY", "SERVICE_SECRET")
if defined?(Dotenv)
  Dotenv.require_keys("DATABASE_URL")
end
