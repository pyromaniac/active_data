module ActiveData
  module Model
    module Attributes
      module Reflections
        class Attribute < Base
          def self.build target, name, *args, &block
            attribute = super
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
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
        end
      end
    end
  end
end
