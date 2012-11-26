module ActiveData
  module Model
    module Localizable
      extend ActiveSupport::Concern

      included do
      end

      module ClassMethods
        def fallbacks locale
          ::I18n.respond_to?(:fallbacks) ? ::I18n.fallbacks[locale] : [locale]
        end

        def locale
          I18n.locale
        end
      end

      def read_localized_attribute name, locale = self.class.locale
        translations = read_attribute(name)
        translations[self.class.fallbacks(locale).detect { |fallback| translations[fallback.to_s] }]
      end
      alias_method :read_localized_attribute_before_type_cast, :read_localized_attribute

      def write_localized_attribute name, value, locale = self.class.locale
        translations = read_attribute(name)
        write_attribute(name, translations.merge(locale.to_s => value))
      end
    end
  end
end
