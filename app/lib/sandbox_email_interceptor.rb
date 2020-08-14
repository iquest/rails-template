# frozen_string_literal: true

# intercept email messages
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ENV['SANDBOX_EMAIL'].split(',') if ENV['SANDBOX_EMAIL'].present?
  end
end
