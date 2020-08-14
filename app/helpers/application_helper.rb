# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Generate `{controller}-{action}-page` class for body element
  def body_class
    path = controller_path.tr('/_', '-')
    action_name_map = {
      index: 'index',
      new: 'edit',
      edit: 'edit',
      update: 'edit',
      patch: 'edit',
      create: 'edit',
      destory: 'index'
    }
    mapped_action_name = action_name_map[action_name.to_sym] || action_name

    if defined?(HighVoltage) && controller.is_a?(HighVoltage::StaticPage) && params.key?(:id) && params[:id] !~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
      id_name = params[:id].tr_s('_', '-')
      [path, id_name].join('-')
    else
      [path, mapped_action_name].join('-')
    end
  end

  # Admin active for helper
  def admin_page?()
    request.path.start_with?('/admin')
  end

  def admin_active_for(controller_name, navbar_name)
    if controller_name.to_s == admin_root_path
      return controller_name.to_s == navbar_name.to_s ? "active" : ""
    end
    navbar_name.to_s.include?(controller_name.to_s) ? 'active' : ''
  end

  def current_path
    request.path
  end

  def flash_class(level)
    case level
    when 'notice', 'success' then 'alert alert-success alert-dismissible'
    when 'info' then 'alert alert-info alert-dismissible'
    when 'warning' then 'alert alert-warning alert-dismissible'
    when 'alert', 'error' then 'alert alert-danger alert-dismissible'
    end
  end

  def app_name
    ENV.fetch('APP_NAME', Rails.application.class.parent_name)
  end

  def current_user
    controller.send(:current_user).decorate
  end
end
