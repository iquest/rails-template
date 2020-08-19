# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def index
      authorize!
    end
  end
end
