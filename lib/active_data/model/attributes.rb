require 'active_data/model/attributes/reflections/base'
require 'active_data/model/attributes/reflections/attribute'
require 'active_data/model/attributes/reflections/collection'
require 'active_data/model/attributes/reflections/dictionary'
require 'active_data/model/attributes/reflections/localized'
require 'active_data/model/attributes/reflections/represents'

require 'active_data/model/attributes/base'
require 'active_data/model/attributes/attribute'
require 'active_data/model/attributes/collection'
require 'active_data/model/attributes/dictionary'
require 'active_data/model/attributes/localized'
require 'active_data/model/attributes/represents'

module ActiveData
  module Model
    module Attributes
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, :_attribute_aliases, instance_reader: false, instance_writer: false
        self._attributes = {}
        self._attribute_aliases = {}

        delegate :attribute_names, :has_attribute?, to: 'self.class'

        %w[attribute collection dictionary].each do |kind|
          define_singleton_method kind do |*args, &block|
            add_attribute("ActiveData::Model::Attributes::Reflections::#{kind.camelize}".constantize, *args, &block)
          end
        end
      end

      module ClassMethods
        def represents(*names, &block)
          options = names.extract_options!
          names.each do |name|
            add_attribute(Reflections::Represents, name, options, &block)
          end
        end

        def add_attribute(reflection_class, *args, &block)
          reflection = reflection_class.build(self, generated_attributes_methods, *args, &block)
          self._attributes = _attributes.merge(reflection.name => reflection)
          reflection
        end

        def alias_attribute(alias_name, attribute_name)
          reflection = reflect_on_attribute(attribute_name)
          raise ArgumentError.new("Can't alias undefined attribute `#{attribute_name}` on #{self}") unless reflection
          reflection.class.generate_methods alias_name, generated_attributes_methods
          self._attribute_aliases = _attribute_aliases.merge(alias_name.to_s => reflection.name)
          reflection
        end

        def reflect_on_attribute(name)
          name = name.to_s
          _attributes[_attribute_aliases[name] || name]
        end

        def has_attribute? name
          name = name.to_s
          _attributes.key?(_attribute_aliases[name] || name)
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

        def inspect
          "#{original_inspect}(#{attributes_for_inspect.presence || 'no attributes'})"
        end

        def represented_attributes
          @represented_attributes ||= _attributes.values.select do |attribute|
            attribute.is_a? ActiveData::Model::Attributes::Reflections::Represents
          end.group_by(&:reference)
        end

        def represented_attribute_names
          @represented_attribute_names ||= Hash[represented_attributes.map do |reference, attributes|
            [reference, attributes.map(&:name)]
          end]
        end

      private

        def original_inspect
          Object.method(:inspect).unbind.bind(self).call
        end

        def attributes_for_inspect
          attribute_names(false).map do |name|
            prefix = respond_to?(:_primary_name) && _primary_name == name ? ?* : ''
            "#{prefix}#{_attributes[name].inspect_reflection}"
          end.join(', ')
        end

        def generated_attributes_methods
          @generated_attributes_methods ||= const_set(:GeneratedAttributesMethods, Module.new)
            .tap { |proxy| include proxy }
        end
      end

      def initialize attrs = {}
        assign_attributes attrs
      end

      def == other
        super || other.instance_of?(self.class) && other.attributes(false) == attributes(false)
      end
      alias_method :eql?, :==

      def attribute(name)
        if reflection = self.class.reflect_on_attribute(name)
          (@_attributes ||= {})[reflection.name] ||= reflection
            .build_attribute(self, @initial_attributes.try(:[], reflection.name))
        end
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
          sanitize = respond_to?(:_primary_name) && name == _primary_name
          logger.info("Ignoring primary `#{name}` attribute value for #{self} during mass-assignment") if sanitize

          if (has_attribute?(name) || respond_to?("#{name}=")) && !sanitize
            public_send("#{name}=", value)
          else
            logger.info("Ignoring undefined `#{name}` attribute value for #{self} during mass-assignment")
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

      def flush! reference
        if names = self.class.represented_attribute_names[reference.to_s]
          names.each { |name| attribute(name).flush! }
        end
      end

    private

      def attributes_for_inspect
        attribute_names(false).map do |name|
          prefix = respond_to?(:_primary_name) && _primary_name == name ? ?* : ''
          "#{prefix}#{attribute(name).inspect_attribute}"
        end.join(', ')
      end
    end
  end
end
