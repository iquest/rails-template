# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    @admin_count = Administrator.all.size
  end
end
