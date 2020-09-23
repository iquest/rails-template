# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def index
      authorize! self, with: Admin::DashboardPolicy
    end
  end
end
