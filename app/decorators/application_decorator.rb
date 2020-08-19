# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  def self.delegate_all
    raise "Do not use delegate_all it is slow, delegate expicit methods"
  end

  private

  def current_user
    context[:current_user]
  end
end
