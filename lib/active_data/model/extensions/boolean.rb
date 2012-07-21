module ActiveData
  module Model
    module Extensions
      module Boolean
        extend ActiveSupport::Concern

        MAPPING = {
          "1" => true,
          "0" => false,
          "t" => true,
          "f" => false,
          "T" => true,
          "F" => false,
          "true" => true,
          "false" => false,
          "TRUE" => true,
          "FALSE" => false
        }

        module ClassMethods
          def modelize value
            MAPPING[value.to_s]
          end
        end
      end
    end
  end
end

Boolean.send :include, ActiveData::Model::Extensions::Boolean
