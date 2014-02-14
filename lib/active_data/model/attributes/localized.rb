module ActiveData
  module Model
    module Attributes
      class Localized < Base
        module ModeMethods
          extend ActiveSupport::Concern

          module ClassMethods
            def fallbacks locale
              ::I18n.respond_to?(:fallbacks) ? ::I18n.fallbacks[locale] : [locale]
            end

            def locale
              I18n.locale
            end
          end

          def write_localized_attribute name, value, locale = self.class.locale
            translations = read_attribute(name)
            write_attribute(name, translations.merge(locale.to_s => value))
          end

          def read_localized_attribute name, locale = self.class.locale
            translations = read_attribute(name)
            translations[self.class.fallbacks(locale).detect { |fallback| translations[fallback.to_s] }.to_s]
          end

          def read_localized_attribute_before_type_cast name, locale = self.class.locale
            translations = read_attribute_before_type_cast(name)
            translations[self.class.fallbacks(locale).detect { |fallback| translations[fallback.to_s] }.to_s]
          end
        end

        def read_value value, context
          Hash[(value.presence || {}).map { |locale, value| [locale.to_s, super(value, context)] }]
        end

        def read_value_before_type_cast value, context
          Hash[(value.presence || {}).map { |locale, value| [locale.to_s, super(value, context)] }]
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

        def generate_class_methods context
        end
      end
    end
  end
end
