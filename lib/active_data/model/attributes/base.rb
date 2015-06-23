module ActiveData
  module Model
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
          enum = options[:enum] || options[:in]
          enum = enum.to_a if enum.respond_to?(:to_a)
          @enum ||= Array.wrap(enum).to_set
        end

        def enumerize value
          value if enum.none? || enum.include?(value)
        end

        def default
          @default ||= options[:default]
        end

        def default?
          @default_ ||= options.key?(:default)
        end

        def default_blank
          @default_blank ||= options[:default_blank]
        end

        def default_blank?
          @default_blank_ ||= options.key?(:default_blank)
        end

        def defaultizer
          @defaultizer ||= default? ? default : default_blank
        end

        def default_value context
          case defaultizer
          when Proc
            if defaultizer.arity == 0
              context.instance_exec(&defaultizer)
            else
              context.instance_exec(context, &defaultizer)
            end
          else
            defaultizer
          end
        end

        def defaultize value, context
          use_default = default_blank? && value.respond_to?(:empty?) ? value.empty? : value.nil?
          use_default ? default_value(context) : value
        end

        def normalizers
          @normalizers ||= Array.wrap(options[:normalize] || options[:normalizer] || options[:normalizers])
        end

        def normalize value, context
          if normalizers.none?
            value
          else
            normalizers.inject(value) do |value, normalizer|
              case normalizer
              when Proc
                context.instance_exec(value, &normalizer)
              when Hash
                normalizer.inject(value) do |value, (name, options)|
                  context.instance_exec(value, options, &ActiveData.normalizer(name))
                end
              else
                context.instance_exec(value, {}, &ActiveData.normalizer(normalizer.to_s))
              end
            end
          end
        end

        def read_value value, context
          normalize(defaultize(enumerize(type_cast(value)), context), context)
        end

        def read_value_before_type_cast value, context
          defaultize(value, context)
        end

        def generate_instance_methods context
          context.class_eval <<-EOS
            def #{name}
              read_attribute('#{name}')
            end

            def #{name}= value
              write_attribute('#{name}', value)
            end

            def #{name}_before_type_cast
              read_attribute_before_type_cast('#{name}')
            end

            def #{name}?
              attribute_present?('#{name}')
            end

            def #{name}_values
              _attributes['#{name}'].enum.to_a
            end

            def #{name}_default
              _attributes['#{name}'].default_value(self)
            end
          EOS
        end

        def generate_class_methods context
          if enum
            context.class_eval <<-EOS
              def #{name}_values
                _attributes['#{name}'].enum.to_a
              end
            EOS
          end
        end
      end
    end
  end
end
