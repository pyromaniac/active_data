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

        # Move represent attribute errors to the top level:
        #
        #   {role: {:'user.email' => ['Some error']}}
        #
        # to:
        #
        #   {email: ['Some error']}
        #
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
                  (errors.messages[name] ||= [])[i] = object.errors.messages
                end
              end
            else
              if association.target && object_invalid?(association.target, deep)
                errors.messages[name] = association.target.errors.messages
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

        def emerge_represented_attributes_errors!
          self.class.represented_attributes.each do |reference, attributes|
            reference_errors = errors.messages[reference.to_sym]
            next unless reference_errors

            attributes_hash = attributes.index_by(&:attribute)
            reference_errors.each do |key, messages|
              name = key.to_s.split(?.).last
              if attributes_hash.key?(name)
                reference_errors.delete(key)
                errors.messages[name.to_sym] ||= []
                errors.messages[name.to_sym].concat(messages)
              end
            end

            errors.messages.delete(reference.to_sym) if reference_errors.empty?
          end
        end
      end
    end
  end
end
