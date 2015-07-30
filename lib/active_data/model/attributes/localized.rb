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
      end
    end
  end
end
