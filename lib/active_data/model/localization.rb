module ActiveData
  module Model
    module Localization
      extend ActiveSupport::Concern

      module ClassMethods
        def localized *args, &block
          options = args.extract_options!
          attribute *args, options.merge(mode: :localized), &block
        end

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
        translations[self.class.fallbacks(locale).detect do |fallback|
          translations[fallback.to_s]
        end.to_s]
      end

      def read_localized_attribute_before_type_cast name, locale = self.class.locale
        translations = read_attribute_before_type_cast(name)
        translations[self.class.fallbacks(locale).detect do |fallback|
          translations[fallback.to_s]
        end.to_s]
      end
    end
  end
end
