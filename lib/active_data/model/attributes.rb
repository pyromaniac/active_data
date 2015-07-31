require 'active_data/model/attributes/reflections/base'
require 'active_data/model/attributes/reflections/attribute'
require 'active_data/model/attributes/reflections/collection'
require 'active_data/model/attributes/reflections/dictionary'
require 'active_data/model/attributes/reflections/localized'

require 'active_data/model/attributes/base'
require 'active_data/model/attributes/attribute'
require 'active_data/model/attributes/collection'
require 'active_data/model/attributes/dictionary'
require 'active_data/model/attributes/localized'

module ActiveData
  module Model
    module Attributes
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, instance_reader: false, instance_writer: false
        self._attributes = {}

        delegate :attribute_names, :has_attribute?, to: 'self.class'

        %w[attribute collection dictionary].each do |kind|
          define_singleton_method kind do |*args, &block|
            add_attribute("ActiveData::Model::Attributes::Reflections::#{kind.camelize}".constantize, *args, &block)
          end
        end
      end

      module ClassMethods
        def add_attribute(reflection_class, *args, &block)
          attribute = reflection_class.build(generated_attributes_methods, *args, &block)
          self._attributes = _attributes.merge(attribute.name => attribute)
          attribute
        end

        def reflect_on_attribute(name)
          _attributes[name.to_s]
        end

        def alias_attribute(alias_name, attribute_name)
          attribute = reflect_on_attribute(attribute_name)
          raise ArgumentError.new("Can't alias undefined attribute `#{attribute_name}` on #{self}") unless attribute
          attribute.alias_attribute alias_name, generated_attributes_methods
        end

        def attribute_names(include_associations = true)
          if include_associations
            _attributes.keys
          else
            _attributes.map do |name, attribute|
              name unless attribute.class == ActiveData::Model::Attributes::Reflections::Base
            end.compact
          end
        end

        def has_attribute? name
          _attributes.key? name.to_s
        end

        def inspect
          "#{original_inspect}(#{attributes_for_inspect.presence || 'no attributes'})"
        end

      private

        def original_inspect
          Object.method(:inspect).unbind.bind(self).call
        end

        def attributes_for_inspect
          attribute_names(false).map do |name|
            "#{name}: #{reflect_on_attribute(name).type}"
          end.join(', ')
        end

        def generated_attributes_methods
          @generated_attributes_methods ||= const_set(:GeneratedAttirbutesMethods, Module.new)
            .tap { |proxy| include proxy }
        end
      end

      def initialize attrs = {}
        @initial_attributes = {}
        assign_attributes attrs
      end

      def == other
        super || other.instance_of?(self.class) && other.attributes(false) == attributes(false)
      end
      alias_method :eql?, :==

      def attribute(name)
        (@_attributes ||= {})[name.to_s] ||= self.class.reflect_on_attribute(name)
          .build_attribute(self, @initial_attributes[name.to_s])
      end

      def write_attribute name, value
        attribute(name).write(value)
      end
      alias_method :[]=, :write_attribute

      def read_attribute name
        attribute(name).read
      end
      alias_method :[], :read_attribute

      def read_attribute_before_type_cast name
        attribute(name).read_before_type_cast
      end

      def attributes(include_associations = true)
        Hash[attribute_names(include_associations).map { |name| [name, read_attribute(name)] }]
      end

      def update attrs
        assign_attributes(attrs)
      end
      alias_method :update_attributes, :update

      def assign_attributes attrs
        (attrs.presence || {}).each do |(name, value)|
          name = name.to_s
          sanitize = respond_to?(:primary_attribute) && name == ActiveData.primary_attribute.to_s
          if (has_attribute?(name) || respond_to?("#{name}=")) && !sanitize
            public_send("#{name}=", value)
          end
        end
      end
      alias_method :attributes=, :assign_attributes

      def inspect
        "#<#{self.class.send(:original_inspect)} #{attributes_for_inspect.presence || '(no attributes)'}>"
      end

      def initialize_copy _
        @initial_attributes = Hash[attribute_names.map do |name|
          [name, read_attribute_before_type_cast(name)]
        end]
        @_attributes = nil
        super
      end

    private

      def attributes_for_inspect
        attribute_names(false).map { |name| attribute(name).inspect_attribute }.join(', ')
      end
    end
  end
end
