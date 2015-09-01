module ActiveData
  module Model
    module Associations
      module Validations
        def valid_ancestry?
          errors.clear
          run_validations!(true)
        end
        alias_method :validate_ancestry, :valid_ancestry?

        def invalid_ancestry?
          !valid_ancestry?
        end

        def validate_ancestry!
          valid_ancestry? || raise_validation_error
        end

      private
        def run_validations!(deep = false) #:nodoc:
          validate_associations!(deep)
          super()
          emerge_represented_attributes_errors!
          errors.empty?
        end

        def validate_associations!(deep)
          association_names.each do |name|
            association = association(name)
            if association.collection?
              association.target.each.with_index do |object, i|
                if object_invalid?(object, deep)
                  object.errors.each do |key, message|
                    key = "#{name}.#{i}.#{key}"
                    errors[key] << message
                    errors[key].uniq!
                  end
                end
              end
            else
              if association.target && object_invalid?(association.target, deep)
                association.target.errors.each do |key, message|
                  key = "#{name}.#{key}"
                  errors[key] << message
                  errors[key].uniq!
                end
              end
            end if deep || association.validate?
          end
        end

        def object_invalid?(object, deep)
          if deep
            object.respond_to?(:invalid_ancestry?) ?
              object.invalid_ancestry? :
              object.invalid?
          else
            object.invalid?
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
          self.class.represented_attributes.each do |reference, attributes|
            attributes.each do |attribute|
              key = :"#{reference}.#{attribute.column}"
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
end
