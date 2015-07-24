module ActiveData
  module Model
    module Attributes
      class Localized < Base
        def read_value value
          Hash[(value.presence || {}).map { |locale, value| [locale.to_s, super(value)] }]
        end

        def read_value_before_type_cast value
          Hash[(value.presence || {}).map { |locale, value| [locale.to_s, super(value)] }]
        end
      end
    end
  end
end
