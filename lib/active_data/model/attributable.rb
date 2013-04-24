module ActiveData
  module Model
    module Attributable
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, :instance_reader => false, :instance_writer => false
        self._attributes = {}

        delegate :attribute_default, :to => 'self.class'
      end

      module ClassMethods
        def build_attribute name, options = {}, &block
          klass = case options[:type].to_s
          when 'Localized'
            ActiveData::Attributes::Localized
          else
            ActiveData::Attributes::Base
          end
          klass.new name, options, &block
        end

        def attribute name, options = {}, &block
          attribute = build_attribute(name, options, &block)
          self._attributes = _attributes.merge(attribute.name => attribute)

          extend generated_class_attributes_methods
          include generated_instance_attributes_methods

          attribute.generate_instance_methods generated_instance_attributes_methods
          attribute.generate_singleton_methods generated_class_attributes_methods
          attribute
        end

        def generated_class_attributes_methods
          @generated_class_attributes_methods ||= Module.new
        end

        def generated_instance_attributes_methods
          @generated_instance_attributes_methods ||= Module.new
        end

        def initialize_attributes
          Hash[_attributes.map { |(name, _)| [name, nil] }]
        end
      end

      def read_attribute name
        name = name.to_s
        cache_attribute name do
          _read_attribute name
        end
      end
      alias_method :[], :read_attribute

      def has_attribute? name
        @attributes.key? name.to_s
      end

      def read_attribute_before_type_cast name
        @attributes[name.to_s]
      end

      def write_attribute name, value
        name = name.to_s
        attribute_cache_clear name
        @attributes[name] = value
      end
      alias_method :[]=, :write_attribute

      def attributes
        Hash[attribute_names.map { |name| [name, send(name)] }]
      end

      def present_attributes
        Hash[attribute_names.map do |name|
          value = send(name)
          [name, value] if value.present?
        end]
      end

      def attribute_names
        @attributes.keys
      end

      def attributes= attributes
        assign_attributes(attributes)
      end

      def update_attributes attributes
        self.attributes = attributes
      end

      def reverse_update_attributes attributes
        reverse_assign_attributes(attributes)
      end

    private

      def _read_attribute name
        attribute = self.class._attributes[name]
        @attributes[name] = attribute.default_value(self) if @attributes[name].nil?
        attribute.type_cast @attributes[name]
      end

      def cache_attribute name, &block
        if attributes_cache.key? name
          attributes_cache[name]
        else
          attributes_cache[name] = block.call
        end
      end

      def attributes_cache
        @attributes_cache ||= {}
      end

      def attribute_cache_clear name
        attributes_cache.delete name
      end

      def assign_attributes attributes
        (attributes.presence || {}).each do |(name, value)|
          send("#{name}=", value) if respond_to?("#{name}=")
        end
      end

      def reverse_assign_attributes attributes
        (attributes.presence || {}).each do |(name, value)|
          send("#{name}=", value) if respond_to?("#{name}=") && respond_to?(name) && send(name).blank?
        end
      end

    end
  end
end
