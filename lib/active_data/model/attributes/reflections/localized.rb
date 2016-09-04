module ActiveData
  module Model
    module Attributes
      module Reflections
        class Localized < Attribute
          def self.build(target, generated_methods, name, *args, &block)
            attribute = super(target, generated_methods, name, *args, &block)
            generate_methods name, generated_methods
            attribute
          end

          def self.generate_methods(name, target)
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
                attribute('#{name}').locale_query(self.class.locale)
              end

              def #{name}_before_type_cast
                attribute('#{name}').read_locale_before_type_cast(self.class.locale)
              end
            RUBY
          end
        end
      end
    end
  end
end
