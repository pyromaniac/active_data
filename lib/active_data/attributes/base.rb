module ActiveData
  module Attributes
    class Base
      attr_reader :name, :options

      def initialize name, options = {}, &block
        @name = name.to_s
        @options = options
        @options[:default] = block if block
      end

      def type
        @type ||= options[:type] || Object
      end

      def values
        @values ||= options[:in].dup if options[:in]
      end

      def default
        @options[:default]
      end

      def default_value instance
        default.respond_to?(:call) ? default.call(instance) : default
      end

      def type_cast value
        value.instance_of?(type) ? value : type.active_data_type_cast(value)
      end

      def generate_instance_methods context
        context.class_eval <<-EOS
          def #{name}
            read_attribute('#{name}')
          end

          def #{name}= value
            write_attribute('#{name}', value)
          end

          def #{name}?
            read_attribute('#{name}').present?
          end

          def #{name}_before_type_cast
            read_attribute_before_type_cast('#{name}')
          end
        EOS
      end

      def generate_singleton_methods context
        if values
          context.class_eval <<-EOS
            def #{name}_values
              _attributes['#{name}'].values
            end
          EOS
        end
      end

    end
  end
end
