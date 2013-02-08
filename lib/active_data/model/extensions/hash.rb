module ActiveData
  module Model
    module Extensions
      module Hash
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            case value
            when ::Hash then
              value
            else
              nil
            end
          end
        end
      end
    end
  end
end

Hash.send :include, ActiveData::Model::Extensions::Hash
