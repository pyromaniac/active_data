module ActiveData
  module Model
    module Attributes
      class ReferenceMany < ReferenceOne
        def read_before_type_cast
          variable_cache(:value_before_type_cast) do
            Array.wrap(@value_cache)
          end
        end

      private

        def type_casted_value
          variable_cache(:value) do
            read_before_type_cast.map { |id| typecast(id) }
          end
        end
      end
    end
  end
end
