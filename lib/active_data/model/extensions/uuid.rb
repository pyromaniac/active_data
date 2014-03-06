module ActiveData
  module Model
    module Extensions
      module UUID
        extend ActiveSupport::Concern

        included do
          def as_json *_
            to_s
          end

          def to_param
            to_s
          end
        end

        module ClassMethods
          def active_data_type_cast value
            case value
            when UUIDTools::UUID
              parse_raw value.raw
            when ActiveData::UUID
              value
            when String
              parse_string value
            when Integer
              parse_int value
            else
              nil
            end
          end

        private

          def parse_string value
            return nil if value.length == 0
            if value.length == 36
              parse value
            elsif value.length == 32
              parse_hexdigest value
            else
              parse_raw value
            end
          end
        end
      end
    end
  end
end

ActiveData::UUID.send :include, ActiveData::Model::Extensions::UUID if defined?(ActiveData::UUID)
