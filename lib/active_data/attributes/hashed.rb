module ActiveData
  module Attributes
    class Hashed < Base
      module ModeMethods
      end

      def read_value value, context
        normalize(Hash[(value.presence || {}).map do |key, value|
          [key, defaultize(enumerize(type_cast(value)), context)]
        end].with_indifferent_access).with_indifferent_access
      end

      def read_value_before_type_cast value, context
        (value.presence || {}).with_indifferent_access
      end
    end
  end
end
