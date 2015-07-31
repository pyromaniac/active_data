module ActiveData
  module Model
    module Attributes
      module Reflections
        class Attribute < Base
          def self.build target, name, *args, &block
            attribute = build_instance(target, name, *args, &block)
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                attribute('#{name}').read
              end

              def #{name}= value
                attribute('#{name}').write(value)
              end

              def #{name}?
                attribute('#{name}').value_present?
              end

              def #{name}_before_type_cast
                attribute('#{name}').read_before_type_cast
              end

              def #{name}_default
                attribute('#{name}').default
              end

              def #{name}_values
                attribute('#{name}').enum.to_a
              end
            RUBY
            attribute
          end

          def alias_attribute alias_name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              alias_method :#{alias_name}, :#{name}
              alias_method :#{alias_name}=, :#{name}=
              alias_method :#{alias_name}?, :#{name}?
              alias_method :#{alias_name}_before_type_cast, :#{name}_before_type_cast
              alias_method :#{alias_name}_default, :#{name}_default
              alias_method :#{alias_name}_values, :#{name}_values
            RUBY
          end

          def defaultizer
            @defaultizer ||= options[:default]
          end

          def typecaster
            @typecaster ||= ActiveData.typecaster(type.ancestors.grep(Class))
          end

          def enumerizer
            @enumerizer ||= options[:enum] || options[:in]
          end

          def normalizers
            @normalizers ||= Array.wrap(options[:normalize] || options[:normalizer] || options[:normalizers])
          end

        private

          def self.build_instance target, name, *args, &block
            options = args.extract_options!
            options.merge!(type: args.first) if args.first
            options.merge!(default: block) if block
            new(name, options)
          end
        end
      end
    end
  end
end
