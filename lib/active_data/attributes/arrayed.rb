module ActiveData
  module Attributes
    class Arrayed < Base
      module ModeMethods
      end

      def read_value value, context
        Array.wrap(value).map { |value| super(value, context) }
      end

      def read_value_before_type_cast value, context
        Array.wrap(value).map { |value| super(value, context) }
      end
    end
  end
end
