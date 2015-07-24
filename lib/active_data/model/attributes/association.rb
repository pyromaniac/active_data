module ActiveData
  module Model
    module Attributes
      class Association < Base
        def read_value value
          value
        end

        def read_value_before_type_cast value
          value
        end
      end
    end
  end
end
