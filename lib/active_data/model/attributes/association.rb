module ActiveData
  module Model
    module Attributes
      class Association < Base
        def read_value value, context
          value
        end

        def read_value_before_type_cast value, context
          read_value value, context
        end

        def generate_instance_methods context
        end

        def generate_instance_alias_methods alias_name, context
        end

        def generate_class_methods context
        end

        def generate_class_alias_methods alias_name, context
        end
      end
    end
  end
end
