module ActiveData
  module Model
    module Extensions
      module DateTime
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            case value
            when ::String then
              ::DateTime.parse value
            when ::Date, ::DateTime, ::Time then
              value.to_date_time
            else
              nil
            end
          end
        end
      end
    end
  end
end

DateTime.send :include, ActiveData::Model::Extensions::DateTime
