# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend
  end

  module ClassMethods
  end
end
