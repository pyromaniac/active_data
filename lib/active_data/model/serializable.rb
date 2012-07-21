module ActiveData
  module Model
    module Serializable

      class UnknownAttribute < ::StandardError
      end

      def serialize value, type
        type.modelize(value)
      end

      def deserialize value
        value.respond_to? :demodelize ? value.demodelize : value.to_s
      end

    end
  end
end
