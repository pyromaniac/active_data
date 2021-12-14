require 'active_model/version'
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
          move_errors(:"#{attribute.reference}.#{attribute.column}", attribute.column)
        end
      end

      if ActiveModel.version >= Gem::Version.new('6.1.0')
        def move_errors(from, to)
          errors[from].each do |error_message|
            errors.add(to, error_message)
            errors.delete(from)
          end
        end
      else # up to 6.0.x
        def move_errors(from, to)
          return unless errors.messages.key?(from) && errors.messages[from].present?

          errors[to].concat(errors.messages[from])
          errors.delete(from)
        end
      end
    end
  end
end
