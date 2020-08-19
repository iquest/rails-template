# frozen_string_literal: true

module ErrorReporting
  extend ActiveSupport::Concern

  included do
    before_action :set_raven_context
  end

  private

  def set_raven_context
    Raven.user_context(id: current_user&.id, email: current_user&.email)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
