# frozen_string_literal: true

class AuthMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'auth/mailer' # to make sure that your mailer uses the devise views
  default from: ENV.fetch('EMAIL_FROM')
  layout "mailer"

  protected

  # WTF
  def template_paths
    super.unshift self.class.default[:template_path]
  end
end
