module ActiveData
  module Model
    module Attributes
      class Collection < Base
        def read_value value
          normalize(Array.wrap(value).map do |value|
            enumerize(typecast(defaultize(value)))
          end)
        end

        def read_value_before_type_cast value
          Array.wrap(value).map { |value| defaultize(value) }
        end
      end
    end
  end
end
