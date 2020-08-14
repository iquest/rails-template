# frozen_string_literal: true

class StaticModel
  module Associations
    include Dry::Core::Constants

    def to_one(assoc, options = EMPTY_HASH)
      foreign_key = options[:foreign_key] || infer_assoc_fk(assoc)
      klass ||= options[:class] || infer_assoc_class(assoc)
      define_assoc_methods(assoc, klass: klass, foreign_key: foreign_key)
    end

    def to_many(assoc, options = EMPTY_HASH)
      foreign_key = options[:foreign_key] || infer_assoc_fk(assoc, many: true)
      klass ||= options[:class] || infer_assoc_class(assoc)
      define_assoc_methods(assoc, klass: klass, foreign_key: foreign_key)
    end

    private

    def define_assoc_methods(assoc, klass:, foreign_key:)
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{assoc}
          @#{assoc} ||= #{klass}.find(send(:#{foreign_key}))
        end
      RUBY
    end

    def infer_assoc_fk(assoc, many: false)
      return "#{assoc}_id" unless many

      "#{assoc}_ids"
    end

    def infer_assoc_class(assoc)
      assoc.to_s.singularize.classify.constantize
    end
  end
end
