module ActiveData
  module Model
    module Attributes
      class Collection < Base
        module ModeMethods
        end

        def read_value value, context
          normalize(Array.wrap(value).map do |value|
            enumerize(type_cast(defaultize(value, context), context), context)
          end, context)
        end

        def read_value_before_type_cast value, context
          Array.wrap(value).map { |value| defaultize(value, context) }
        end
      end
    end
  end
end
