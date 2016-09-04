class Boolean; end unless defined?(Boolean)

begin
  require 'uuidtools'
rescue LoadError
  nil
else
  module ActiveData
    class UUID < UUIDTools::UUID
      def as_json(*_)
        to_s
      end

      def to_param
        to_s
      end

      def self.parse_string(value)
        return nil if value.length.zero?
        if value.length == 36
          parse value
        elsif value.length == 32
          parse_hexdigest value
        else
          parse_raw value
        end
      end

      def inspect
        "#<ActiveData::UUID:#{self}>"
      end
    end
  end
end
