module ActiveData
  module Model
    module Extensions
      module Boolean
        extend ActiveSupport::Concern

        MAPPING = {
          1 => true,
          0 => false,
          '1' => true,
          '0' => false,
          't' => true,
          'f' => false,
          'T' => true,
          'F' => false,
          true => true,
          false => false,
          'true' => true,
          'false' => false,
          'TRUE' => true,
          'FALSE' => false,
          'y' => true,
          'n' => false,
          'yes' => true,
          'no' => false,
        }

        module ClassMethods
          def active_data_type_cast value
            MAPPING[value]
          end
        end
      end
    end
  end
end

Boolean.send :include, ActiveData::Model::Extensions::Boolean
