module ActiveData
  module Model
    module Extensions
      module Array
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            case value
            when ::Array then
              value
            when ::String then
              value.split(',').map(&:strip)
            else
              nil
            end
          end
        end
      end
    end
  end
end

Array.send :include, ActiveData::Model::Extensions::Array
