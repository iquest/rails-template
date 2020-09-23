# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def update?
    user == record || user.role?(:admin)
  end
end
