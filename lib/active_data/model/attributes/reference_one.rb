module ActiveData
  module Model
    module Attributes
      class ReferenceOne < Base
        TYPES = {
          integer: Integer,
          float: Float,
          decimal: BigDecimal,
          datetime: Time,
          timestamp: Time,
          time: Time,
          date: Date,
          text: String,
          string: String,
          binary: String,
          boolean: Boolean
        }

        def write value
          pollute do
            previous = type_casted_value
            result = write_value value
            if (!value.nil? && type_casted_value.nil?) || type_casted_value != previous
              association.reset
            end
            result
          end
        end

        def read
          if association.target
            association.identify
          else
            type_casted_value
          end
        end

        def read_before_type_cast
          @value_cache
        end

        def type
          @type ||= begin
            association_reflection = association.reflection
            column = association_reflection.klass.columns_hash[association_reflection.primary_key.to_s]
            TYPES[column.type]
          end
        end

        def typecaster
          @typecaster ||= ActiveData.typecaster(type.ancestors.grep(Class))
        end

      private

        def type_casted_value
          variable_cache(:value) do
            typecast(read_before_type_cast)
          end
        end

        def association
          @association ||= owner.association(reflection.association)
        end
      end
    end
  end
end
