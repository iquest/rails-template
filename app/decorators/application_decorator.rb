# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  include ActionPolicy::Behaviour
  authorize :user, through: :current_user

  def self.delegate_all
    raise "Do not use delegate_all it is slow, delegate expicit methods"
  end

  private

  def current_user
    h.current_user
  end

  def t(*args)
    I18n.t(*args)
  end
end
