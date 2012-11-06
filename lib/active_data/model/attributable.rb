require 'active_data/model/serializable'

module ActiveData
  module Model
    module Attributable
      include Serializable
      extend ActiveSupport::Concern

      included do
        class_attribute :_attributes, :instance_reader => false, :instance_writer => false
        self._attributes = ActiveSupport::HashWithIndifferentAccess.new

        delegate :attribute_default, :to => 'self.class'
      end

      module ClassMethods
        def attribute name, options = {}, &block
          default = options.is_a?(Hash) ? options[:default] : options
          type = options.is_a?(Hash) ? normalize_type(options[:type]) : String
          self._attributes = self._attributes.merge(name => {
            default: (block || default),
            type: type
          })

          define_method name do
            read_attribute(name)
          end
          define_method "#{name}_before_type_cast" do
            read_attribute_before_type_cast(name)
          end
          define_method "#{name}?" do
            read_attribute(name).present?
          end
          define_method "#{name}=" do |value|
            write_attribute(name, value)
          end

          if options.is_a?(Hash) && options[:in]
            define_singleton_method "#{name}_values" do
              options[:in].dup
            end
          end
        end

        def normalize_type type
          case type
          when String, Symbol then
            type.to_s.camelize.safe_constantize
          when nil then
            String
          else
            type
          end
        end

        def attribute_default name, instance = nil
          default = _attributes[name][:default]
          default.respond_to?(:call) ? default.call(instance) : default
        end

        def initialize_attributes
          _attributes.inject(ActiveSupport::HashWithIndifferentAccess.new) do |result, (name, value)|
            result[name] = nil
            result
          end
        end
      end

      def read_attribute name
        @attributes[name].nil? ? attribute_default(name, self) : @attributes[name]
      end
      alias_method :[], :read_attribute

      def has_attribute? name
        @attributes.key? name
      end

      def read_attribute_before_type_cast name
        deserialize(send(name))
      end

      def write_attribute name, value
        type = self.class._attributes[name][:type]
        @attributes[name] = serialize(value, type)
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

      def assign_attributes attributes
        (attributes.presence || {}).each do |(name, value)|
          send("#{name}=", value) if respond_to?("#{name}=")
        end
        self.attributes
      end

      def reverse_assign_attributes attributes
        (attributes.presence || {}).each do |(name, value)|
          send("#{name}=", value) if respond_to?("#{name}=") && respond_to?(name) && send(name).blank?
        end
        self.attributes
      end

    end
  end
end
