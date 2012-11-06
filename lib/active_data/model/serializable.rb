module ActiveData
  module Model
    module Serializable

      class UnknownAttribute < ::StandardError
      end

      def serialize value, type
        type.modelize(value)
      end

      def deserialize value
        value.demodelize
      end

    end
  end
end
