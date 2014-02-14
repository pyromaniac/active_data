module ActiveData
  module Model
    module Attributes
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, instance_writer: false
        self._attributes = {}

        delegate :attribute_default, to: 'self.class'
      end

      module ClassMethods
        def attribute name, options = {}, &block
          attribute = build_attribute(name, options, &block)
          self._attributes = _attributes.merge(attribute.name => attribute)

          include attribute.class::ModeMethods
          attribute.generate_instance_methods generated_instance_attributes_methods
          attribute.generate_class_methods generated_class_attributes_methods
          attribute
        end

        def build_attribute name, options = {}, &block
          class_name = "ActiveData::Model::Attributes::#{(options.delete(:mode).to_s.presence || 'base').classify}"
          class_name.safe_constantize.new name, options, &block
        end

        def generated_class_attributes_methods
          @generated_class_attributes_methods ||= Module.new.tap { |proxy| extend proxy }
        end

        def generated_instance_attributes_methods
          @generated_instance_attributes_methods ||= Module.new.tap { |proxy| include proxy }
        end

        def initialize_attributes
          Hash[_attributes.keys.zip]
        end

        def create attributes = {}
          new attributes
        end
      end

      def has_attribute? name
        @attributes.key? name.to_s
      end

      def write_attribute name, value
        name = name.to_s
        attributes_cache.delete name
        @attributes[name] = value
      end
      alias_method :[]=, :write_attribute

      def read_attribute name
        name = name.to_s
        if attributes_cache.key? name
          attributes_cache[name]
        else
          attributes_cache[name] = _attributes[name].read_value(@attributes[name], self)
        end
      end
      alias_method :[], :read_attribute

      def read_attribute_before_type_cast name
        name = name.to_s
        _attributes[name].read_value_before_type_cast(@attributes[name], self)
      end

      def attributes
        Hash[attribute_names.map { |name| [name, send(name)] }]
      end

      def present_attributes
        Hash[attribute_names.map do |name|
          value = send(name)
          [name, value] unless value.respond_to?(:empty?) ? value.empty? : value.nil?
        end.compact]
      end

      def attribute_names
        @attributes.keys
      end

      def update attributes
        assign_attributes(attributes)
      end
      alias_method :update_attributes, :update

      def assign_attributes attributes
        (attributes.presence || {}).each do |(name, value)|
          send("#{name}=", value) if has_attribute?(name) || respond_to?("#{name}=")
        end
      end
      alias_method :attributes=, :assign_attributes

    private

      def attributes_cache
        @attributes_cache ||= {}
      end
    end
  end
end
