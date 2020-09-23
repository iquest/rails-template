# frozen_string_literal: true

class AdminPolicy < ActionPolicy::Base
  default_rule :manage?
  alias_rule :index?, :create?, :new?, to: :manage?

  def manage?
    user.role?(:admin)
  end
end
