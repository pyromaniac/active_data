module ActiveData
  module Model
    module Attributes
      module Reflections
        class Localized < Attribute
          def self.build target, name, *args, &block
            attribute = build_reflection(target, name, *args, &block)
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}_translations
                attribute('#{name}').read
              end

              def #{name}_translations= value
                attribute('#{name}').write(value)
              end

              def #{name}
                attribute('#{name}').read_locale(self.class.locale)
              end

              def #{name}= value
                attribute('#{name}').write_locale(value, self.class.locale)
              end

              def #{name}?
                attribute('#{name}').locale_value_present?(self.class.locale)
              end

              def #{name}_before_type_cast
                attribute('#{name}').read_locale_before_type_cast(self.class.locale)
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
