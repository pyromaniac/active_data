require 'active_data/model/attributes/base'
require 'active_data/model/attributes/collection'
require 'active_data/model/attributes/dictionary'
require 'active_data/model/attributes/localized'
require 'active_data/model/attributes/association'


module ActiveData
  module Model
    module Attributes
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, instance_writer: false
        self._attributes = {}

        delegate :attribute_names, :attribute_default, :has_attribute?, to: 'self.class'

        [:collection, :dictionary, :localized].each do |mode|
          define_singleton_method mode do |*args, &block|
            options = args.extract_options!
            attribute *args, options.merge(mode: mode), &block
          end
        end
      end

      module ClassMethods
        def attribute name, *args, &block
          options = args.extract_options!
          options = options.merge(type: args.first) if args.first
          attribute = build_attribute(name, options, &block)
          self._attributes = _attributes.merge(attribute.name => attribute)

          include attribute.class::ModeMethods
          attribute.generate_instance_methods generated_instance_attributes_methods
          attribute.generate_class_methods generated_class_attributes_methods
          attribute
        end

        def alias_attribute(alias_name, attribute_name)
          attribute = _attributes[attribute_name.to_s]
          raise ArgumentError.new("Can't alias undefined attribute `#{attribute_name}` on #{self}") unless attribute
          attribute.generate_instance_alias_methods alias_name, generated_instance_attributes_methods
          attribute.generate_class_alias_methods alias_name, generated_class_attributes_methods
          attribute
        end

        def attribute_names(include_associations = true)
          if include_associations
            _attributes.keys
          else
            _attributes.map do |name, attribute|
              name unless attribute.is_a?(ActiveData::Model::Attributes::Association)
            end.compact
          end
        end

        def has_attribute? name
          _attributes.key? name.to_s
        end

        def inspect
          attributes = _attributes.map { |name, attribute| "#{name}: #{attribute.type}" }.join(', ')
          "#{inspect_model_name} (#{attributes.presence || 'no attributes'})"
        end

        def initialize_attributes
          Hash[attribute_names.zip]
        end

      private

        def build_attribute name, options = {}, &block
          class_name = "ActiveData::Model::Attributes::#{(options.delete(:mode).to_s.presence || 'base').classify}"
          class_name.constantize.new name, options, &block
        end

        def generated_class_attributes_methods
          @generated_class_attributes_methods ||= Module.new.tap { |proxy| extend proxy }
        end

        def generated_instance_attributes_methods
          @generated_instance_attributes_methods ||= Module.new.tap { |proxy| include proxy }
        end

        def inspect_model_name
          name.presence || "[anonymous model]:#{object_id}"
        end
      end

      def initialize attrs = {}
        @attributes = self.class.initialize_attributes
        assign_attributes attrs
      end

      def == other
        super || other.instance_of?(self.class) && other.attributes(false) == attributes(false)
      end
      alias_method :eql?, :==

      def write_attribute name, value
        name = name.to_s
        attributes_cache.delete name
        @attributes[name] = value
      end
      alias_method :[]=, :write_attribute

      def read_attribute name
        name = name.to_s
        attributes_cache.fetch(name) do
          attributes_cache[name] = _attributes[name].read_value(@attributes[name], self)
        end
      end
      alias_method :[], :read_attribute

      def read_attribute_before_type_cast name
        name = name.to_s
        _attributes[name].read_value_before_type_cast(@attributes[name], self)
      end

      def attribute_present? name
        value = read_attribute name
        !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
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
        attributes = attribute_names(false).map { |name| "#{name}: #{attribute_for_inspect(name)}" }.join(', ')
        "#<#{self.class.send(:inspect_model_name)}:#{object_id} (#{attributes.presence || 'no attributes'})>"
      end

      def initialize_copy _
        @attributes = attributes.clone
        @attributes_cache = attributes_cache.clone
        super
      end

      def freeze
        @attributes = @attributes.clone.freeze
        self
      end

      def frozen?
        @attributes.frozen?
      end

    private

      def attribute_for_inspect(name)
        value = read_attribute(name)

        if value.is_a?(String) && value.length > 50
          "#{value[0..50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_s(:db)}")
        else
          value.inspect
        end
      end

      def attributes_cache
        @attributes_cache ||= {}
      end
    end
  end
end
