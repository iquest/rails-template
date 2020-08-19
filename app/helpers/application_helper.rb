# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def title(page_title = nil)
    page_title ||= yield if block_given?
    content_for(:title) { page_title.to_s }
  end

  def table(collection, model:, id: "", columns: [], links: [], row_link: nil)
    render "application/table", model: model, collection: collection, id: id, columns: columns,
                                links: links, row_link: row_link
  end

  def filter_form_for(query, **opts)
    search_form_for query,
                    html: {class: "form-inline mb-4"},
                    wrapper: :filter_form,
                    wrapper_mappings: {boolean: :filter_inline_boolean}, **opts do |f|
      concat yield f
      concat link_to t('application.reset_filter'), url_for(q: nil, commit: nil), alt: t('application.reset_filter'), class: "btn btn-secondary form-group mt-auto mx-1"
    end
  end

  def new_link(model, policy: nil, **options)
    unless policy == false
      model_policy = policy || "#{model}Policy".classify.constantize
      return unless allowed_to? :create?, model, with: model_policy
    end

    icon = options.delete(:icon)
    icon ||= "plus fw" unless icon == false
    html_class = ["btn bg-primary border-0 text-white mb-3", options.delete(:class)].join(" ")
    style = options.delete(:style) || nil
    method = options.delete(:method) || :get
    path = options.delete(:path) || new_polymorphic_path(model)
    text = options.delete(:text)
    title = options.delete(:title) || text || t('application.add', name: model.model_name.human.downcase)
    text ||= model.model_name.human

    link_to path, title: title, method: method, class: html_class, style: style do
      concat fa_icon(icon, text: "&nbsp;".html_safe) if icon
      concat text
    end
  end

  def index_link(model, _body = nil, policy: nil, **options)
    unless policy == false
      model_policy = policy || "#{model}Policy".classify.constantize
      return unless allowed_to? :index?, model, with: model_policy
    end

    link_to polymorphic_path(model), class: options[:class] do
      if options[:icon]
        concat fa_icon(options[:icon])
        concat "&nbsp;".html_safe
      end
      concat model.model_name.human(count: 2)
    end
  end

  def authorized_link(model, text = nil, **options)
    policy = options.delete(:policy)
    unless policy == false
      model_policy = policy || ActionPolicy.lookup(model, options)
      return unless allowed_to? :index?, model, with: model_policy
    end

    text = yield if block_given?
    html_class = options.delete(:class)
    action = options.delete(:action)
    icon = options.delete(:icon)

    link_to polymorphic_path(model, action: action, **options), class: html_class do
      if icon
        concat fa_icon(icon)
        concat "&nbsp;".html_safe
      end
      concat text if text
    end
  end

  def description_list(_variant = :default, description_values = {})
    render "application/description_list", description_values: description_values
  end

  def dl(description_values = {})
    description_list(:default, description_values)
  end

  FLASH_COLORS = {
    notice: "info",
    success: "success",
    error: "danger",
    alert: "danger"
  }.tap do |h|
    h.default_proc = proc { |hash, key| hash[key] = "info" }
  end

  def flash_color(level)
    FLASH_COLORS[level.to_sym]
  end

  def format_date(date, format = :short, locale: I18n.locale)
    l(date, format: format, locale: locale) unless date.nil?
  end

  def human(model, attribute = nil, count: 1)
    if attribute
      model.human_attribute_name(attribute)
    else
      model.model_name.human(count: count)
    end
  end

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
  def admin_page?
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
    ENV.fetch('APP_NAME', Rails.application.class.module_parent_name)
  end

  def current_user
    controller.send(:current_user).decorate
  end
end
