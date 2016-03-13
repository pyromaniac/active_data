module ActiveData
  module Model
    module Associations
      module Validations
        def valid_ancestry?
          errors.clear
          validate_nested!
          run_validations!
        end
        alias_method :validate_ancestry, :valid_ancestry?

        def invalid_ancestry?
          !valid_ancestry?
        end

        def validate_ancestry!
          valid_ancestry? || raise_validation_error
        end

      private

        def run_validations! #:nodoc:
          super
          emerge_represented_attributes_errors!
          errors.empty?
        end

        def validate_nested!
          association_names.each do |name|
            association = association(name)
            invalid_block = if association.reflection.klass.method_defined?(:invalid_ansestry?)
              lambda { |object| object.invalid_ansestry? }
            else
              lambda { |object| object.invalid? }
            end

            ActiveData::Model::Validations::NestedValidator
              .validate_nested(self, name, association.target, &invalid_block)
          end
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
            messages = errors.messages[key]
            if messages.present?
              errors[attribute.column].concat(messages)
              errors.delete(key)
            end
          end
        end
      end
    end
  end
end
