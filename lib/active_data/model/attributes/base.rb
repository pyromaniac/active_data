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
          @type ||= options[:type].is_a?(Class) ? options[:type] :
            options[:type].present? ? options[:type].to_s.camelize.constantize : Object
        end

        def type_cast value, context
          if value.instance_of?(type)
            value
          else
            context.instance_exec(value, type, &ActiveData.typecaster(type_parent_classes)) unless value.nil?
          end
        end

        def enum context
          if enumerizer.is_a?(Proc)
            enum = if enumerizer.arity == 0
              context.instance_exec(&enumerizer)
            else
              context.instance_exec(context, &enumerizer)
            end

            case enum
            when Range
              enum.to_a.to_set
            when Set
              enum
            else
              Array.wrap(enum).to_set
            end
          else
            @enum ||= begin
              enum = enumerizer.respond_to?(:to_a) ? enumerizer.to_a : enumerizer
              Array.wrap(enum).to_set
            end
          end
        end

        def enumerize value, context
          value if enum(context).none? || enum(context).include?(value)
        end

        def enumerizer
          @enumerizer ||= options[:enum] || options[:in]
        end

        def enumerizer?
          @enumerizer_ ||= options.key?(:enum) || options.key?(:in)
        end

        def default context
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
          value.nil? ? default(context) : value
        end

        def defaultizer
          @defaultizer ||= options[:default]
        end

        def defaultizer?
          @default_ ||= options.key?(:default)
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
                  context.instance_exec(value, options, self, &ActiveData.normalizer(name))
                end
              else
                context.instance_exec(value, {}, self, &ActiveData.normalizer(normalizer.to_s))
              end
            end
          end
        end

        def normalizers
          @normalizers ||= Array.wrap(options[:normalize] || options[:normalizer] || options[:normalizers])
        end

        def read_value value, context
          normalize(enumerize(type_cast(defaultize(value, context), context), context), context)
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

            def #{name}?
              attribute_present?('#{name}')
            end

            def #{name}_before_type_cast
              read_attribute_before_type_cast('#{name}')
            end

            def #{name}_default
              _attributes['#{name}'].default(self)
            end

            def #{name}_values
              _attributes['#{name}'].enum(self).to_a
            end
          EOS
        end

        def generate_instance_alias_methods alias_name, context
          context.class_eval <<-EOS
            alias_method :#{alias_name}, :#{name}
            alias_method :#{alias_name}=, :#{name}=
            alias_method :#{alias_name}?, :#{name}?
            alias_method :#{alias_name}_before_type_cast, :#{name}_before_type_cast
            alias_method :#{alias_name}_default, :#{name}_default
            alias_method :#{alias_name}_values, :#{name}_values
          EOS
        end

        def generate_class_methods context
          if enumerizer? && !enumerizer.is_a?(Proc)
            context.class_eval <<-EOS
              def #{name}_values
                _attributes['#{name}'].enum(nil).to_a
              end
            EOS
          end
        end

        def generate_class_alias_methods alias_name, context
          if enumerizer? && !enumerizer.is_a?(Proc)
            context.class_eval <<-EOS
              alias_method :#{alias_name}_values, :#{name}_values
            EOS
          end
        end

      private

        def type_parent_classes
          @type_parent_classes ||= type.ancestors.grep(Class)
        end
      end
    end
  end
end
