require 'active_data/model/attributes/reflections/represents'
require 'active_data/model/attributes/represents'

module ActiveData
  module Model
    module Representation
      extend ActiveSupport::Concern

      included do
        prepend PrependMethods
      end

      module PrependMethods
        def assign_attributes(attrs)
          if self.class.represented_attributes.present?
            attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
            attrs = attrs.stringify_keys
            represented_attrs = self.class.represented_names_and_aliases
              .each_with_object({}) do |name, result|
                result[name] = attrs.delete(name) if attrs.key?(name)
              end

            super(attrs.merge!(represented_attrs))
          else
            super(attrs)
          end
        end
        alias_method :attributes=, :assign_attributes
      end

      module ClassMethods
        def represents(*names, &block)
          options = names.extract_options!
          names.each do |name|
            add_attribute(ActiveData::Model::Attributes::Reflections::Represents, name, options, &block)
          end
        end

        def represented_attributes
          @represented_attributes ||= _attributes.values.select do |attribute|
            attribute.is_a? ActiveData::Model::Attributes::Reflections::Represents
          end
        end

        def represented_names_and_aliases
          @represented_names_and_aliases ||= represented_attributes.flat_map do |attribute|
            [attribute.name, *inverted_attribute_aliases[attribute.name]]
          end
        end
      end

    private

      def run_validations! #:nodoc:
        super
        emerge_represented_attributes_errors!
        errors.empty?
      end

      # Move represent attribute errors to the top level:
      #
      #   {:'role.email' => ['Some error']}
      #
      # to:
      #
      #   {email: ['Some error']}
      #
      def emerge_represented_attributes_errors!
        self.class.represented_attributes.each do |attribute|
          key = :"#{attribute.reference}.#{attribute.column}"
          # Rails 5 pollutes messages with an empty array on key data fetch attempt
          messages = errors.messages[key] if errors.messages.key?(key)
          if messages.present?
            errors[attribute.column].concat(messages)
            errors.delete(key)
          end
        end
      end
    end
  end
end
