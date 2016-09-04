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
          @value_before_type_cast ||= Hash[(@value_cache.presence || {}).map do |locale, value|
            [locale.to_s, defaultize(value)]
          end]
        end

        def write_locale(value, locale)
          pollute do
            write(read.merge(locale.to_s => value))
          end
        end

        def read_locale(locale)
          read[owner.class.fallbacks(locale).detect do |fallback|
            read[fallback.to_s]
          end.to_s]
        end

        def read_locale_before_type_cast(locale)
          read_before_type_cast[owner.class.fallbacks(locale).detect do |fallback|
            read_before_type_cast[fallback.to_s]
          end.to_s]
        end

        def locale_query(locale)
          value = read_locale(locale)
          !(value.respond_to?(:zero?) ? value.zero? : value.blank?)
        end
      end
    end
  end
end
