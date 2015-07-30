module ActiveData
  module Model
    module Attributes
      class Association < Base
        def read
          @raw_value
        end

        def read_before_type_cast
          @raw_value
        end
      end
    end
  end
end
