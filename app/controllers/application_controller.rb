# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ErrorReporting
  include Settable
  include Pagination
  before_action :store_user_location!, if: :storable_location?
  # before_action :authenticate_user!
  before_action :store_back_location

  authorize :user, through: :current_user
  verify_authorized unless: :devise_controller?

  rescue_from ActionPolicy::Unauthorized do |e|
    logger.error "#{e.class} #{e.message} #{e.result.reasons.full_messages}"
    redirect_back fallback_location: root_path, alert: e.result.message
  end

  rescue_from Pagy::OverflowError do |e|
    logger.error "#{e.class} #{e.message}"
    redirect_to url_for(page: e.pagy.last), notice: "Page ##{params[:page]} is overflowing. Showing page #{e.pagy.last} instead."
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    logger.error "#{e.class} #{e.message}"
    redirect_back fallback_location: root_path, alert: e.message
  end

  class << self
  end

  private

  # shortcut to render with locals
  def display(locals = {})
    render locals: locals
  end

  # returns authorized attributes from params[:key]
  # rubocop:disable Naming/MethodParameterName
  def attributes(key, as = nil, **options)
    return {} unless params.key?(key)

    if as
      authorized(params.require(key), as: as, **options)
    else
      authorized(params.require(key), **options)
    end.to_h.deep_symbolize_keys
  end

  def unsafe_attributes(key)
    params.require(key).to_unsafe_h.deep_symbolize_keys
  end
  # rubocop:enable Naming/MethodParameterName

  def decorate(object, decorator = nil, context: decorator_context)
    return decorator.decorate(object, context: context) if decorator

    object.decorate(context: context)
  end

  def decorator_context
    {current_user: current_user}
  end

  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? && !signed_in?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def store_back_location!
    session[:back_location] = request.referer
  end

  def store_back_location
    store_back_location! if store_back_location?
  end

  def store_back_location?
    request.get? &&
      is_navigational_format? &&
      !request.xhr? &&
      signed_in? &&
      request.original_url != request.referer
  end

  def back_location
    session[:back_location]
  end
  helper_method :back_location

  def redirect_to_back_location(fallback_location: root_path, **options)
    if back_location
      redirect_to back_location, options
      session.delete(:back_location)
    else
      redirect_to fallback_location, options
    end
  end

  def after_sign_in_path_for(resource)
    stored_location = stored_location_for(resource)
    return stored_location if stored_location

    if current_user.role?(:admin)
      admin_root_path
    else
      root_path
    end
  end
end
