module ActiveData
  module Attributes
    class Base
      module ModeMethods
      end

      attr_reader :name, :options

      def initialize name, options = {}, &block
        @name = name.to_s
        @options = options
        @options[:default] = block if block
      end

      def type
        @type ||= options[:type] || Object
      end

      def type_cast value
        value.instance_of?(type) ? value : type.active_data_type_cast(value)
      end

      def enum
        @enum ||= Array.wrap(options[:enum] || options[:in]).to_set
      end

      def enumerize value
        value if enum.none? || enum.include?(value)
      end

      def default
        @default ||= options[:default]
      end

      def default_blank?
        @default_blank ||= !!options[:default_blank]
      end

      def default_value context
        default.respond_to?(:call) ? default.call(context) : default unless default.nil?
      end

      def defaultize value, context
        use_default = default_blank? && value.respond_to?(:empty?) ? value.empty? : value.nil?
        use_default ? default_value(context) : value
      end

      def normalizers
        @normalizers ||= Array.wrap(options[:normalizer] || options[:normalizers])
      end

      def normalize value
        normalizers.none? ? value : normalizers.inject(value) do |value, normalizer|
          normalizer.is_a?(Proc) ? normalizer.call(value) :
            normalizer.is_a?(Hash) ? normalizer.inject(value) do |value, (name, options)|
              ActiveData.normalizer(name).call(value, options)
            end : ActiveData.normalizer(normalizer).call(value, {})
        end
      end

      def read_value value, context
        defaultize(enumerize(normalize(type_cast(value))), context)
      end

      def read_value_before_type_cast value, context
        value
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

      def generate_class_methods context
        if enum
          context.class_eval <<-EOS
            def #{name}_values
              _attributes['#{name}'].enum
            end
          EOS
        end
      end

    end
  end
end
