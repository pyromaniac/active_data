module ActiveData
  module Model
    module Attributes
      module Reflections
        class Localized < Base
          def self.build target, name, *args, &block
            attribute = super
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
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
            RUBY
            attribute
          end

          def alias_attribute alias_name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              alias_method :#{alias_name}_translations, :#{name}_translations
              alias_method :#{alias_name}_translations=, :#{name}_translations=
              alias_method :#{alias_name}, :#{name}
              alias_method :#{alias_name}=, :#{name}=
              alias_method :#{alias_name}?, :#{name}?
              alias_method :#{alias_name}_before_type_cast, :#{name}_before_type_cast
            RUBY
          end
        end
      end
    end
  end
end
