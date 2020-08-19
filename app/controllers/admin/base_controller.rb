# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout 'admin'

    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      return true if current_user&.role?(:admin)

      redirect_to login_path
      false
    end

    alias_method :current_admin, :current_user
  end
end
