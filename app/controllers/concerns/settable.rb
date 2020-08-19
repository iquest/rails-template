# frozen_string_literal: true

module Settable
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def set(name, &blk)
      iv = "@#{name}"

      define_method name do
        return instance_variable_get iv if instance_variable_defined? iv

        instance_variable_set iv, instance_eval(&blk)
      end

      define_method :"#{name}=" do |value|
        instance_variable_set iv, value
      end
      private :"#{name}="
    end

    alias_method :let, :set
  end
end
