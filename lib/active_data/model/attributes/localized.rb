module ActiveData
  module Model
    module Attributes
      class Localized < Attribute
        def read
          @value ||= Hash[read_before_type_cast.map do |locale, value|
            [locale.to_s, normalize(enumerize(typecast(value)))]
          end]
        end

        def read_before_type_cast
          @value_before_type_cast ||= Hash[(@raw_value.presence || {}).map do |locale, value|
            [locale.to_s, defaultize(value)]
          end]
        end

        def read_locale locale
          read[owner.class.fallbacks(locale).detect do |fallback|
            read[fallback.to_s]
          end.to_s]
        end

        def read_locale_before_type_cast locale
          read_before_type_cast[owner.class.fallbacks(locale).detect do |fallback|
            read_before_type_cast[fallback.to_s]
          end.to_s]
        end

        def write_locale value, locale
          write(read.merge(locale.to_s => value))
        end

        def locale_value_present? locale
          value = read_locale(locale)
          !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end
