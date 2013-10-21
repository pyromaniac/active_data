module ActiveData
  module Attributes
    class Arrayed < Base
      module ModeMethods
      end

      def read_value value, context
        normalize(Array.wrap(value).map do |value|
          type_cast(value)
        end).map do |value|
          defaultize(enumerize(value), context)
        end
      end

      def read_value_before_type_cast value, context
        Array.wrap(value).map { |value| value }
      end
    end
  end
end
