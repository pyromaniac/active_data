module ActiveData
  module Attributes
    class Localized < Base

      def default_value *args
        {}
      end

      def generate_instance_methods context
        context.class_eval <<-EOS
          def #{name}_translations
            read_attribute('#{name}')
          end

          def #{name}_translations= value
            write_attribute('#{name}', value)
          end

          def #{name}
            read_localized_attribute('#{name}')
          end

          def #{name}= value
            write_localized_attribute('#{name}', value)
          end

          def #{name}?
            read_localized_attribute('#{name}').present?
          end

          def #{name}_before_type_cast
            read_localized_attribute_before_type_cast('#{name}')
          end
        EOS
      end

      def generate_singleton_methods context
      end

    end
  end
end
