module ActiveData
  module Model
    module Attributes
      class Collection < Base
        def read
          @value ||= normalize(read_before_type_cast.map do |value|
            enumerize(typecast(value))
          end)
        end

        def read_before_type_cast
          @value_before_type_cast ||= Array.wrap(@raw_value).map { |value| defaultize(value) }
        end
      end
    end
  end
end
