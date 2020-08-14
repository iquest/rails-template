# frozen_string_literal: true

require "dry-core"

class StaticModel < Dry::Struct
  # convert string keys to symbols
  transform_keys(&:to_sym)

  # resolve default types on nil
  transform_types do |type|
    if type.default?
      type.constructor do |value|
        value.nil? ? Dry::Types::Undefined : value
      end
    else
      type
    end
  end

  # activemodel compat
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion
  include ActiveModel::Serialization

  class_attribute :loader, instance_accessor: false, default: proc { [] }
  class_attribute :pk, instance_accessor: false, default: :id

  module ClassMethods
    def data(&block)
      if block_given?
        self.loader = block
      else
        loader.call
      end
    end

    def primary_key(attr)
      self.pk = attr.to_sym
      class_eval("def id; @attributes[:#{attr}]; end", __FILE__, __LINE__)
    end

    def all
      @all ||= data.map { |item| new(item) }.freeze
    end

    def where(**conditions)
      all.dup.tap do |result|
        conditions.each do |k, v|
          result.select! { |obj| obj.send(k) == v }
        end
      end
    end

    def [](id)
      return unless pk

      all.detect { |obj| obj.send(pk) == pk_type[id] }
    end

    alias find []

    def find_by(key_val)
      key = key_val.keys.first.to_sym
      val = key_val.values.first
      all.detect { |pm| pm.send(key) == val }
    end

    private

    def pk_type
      @pk_type ||= schema.keys.detect { |k| k.name == pk }
    end

    def load_yaml(filename)
      self.data = YAML.load_file(filename)
    end
  end
  extend ClassMethods
  extend Associations
end
