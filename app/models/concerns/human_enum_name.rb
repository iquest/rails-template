# frozen_string_literal: true

module HumanEnumName
  extend ActiveSupport::Concern

  class_methods do
    def human_enum_name(enum, value)
      human_attribute_name("#{enum}/#{value}")
    end
  end
end
