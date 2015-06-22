module ActiveData
  module Model
    module Extensions
      module DateTime
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.try(:to_datetime)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end

DateTime.send :include, ActiveData::Model::Extensions::DateTime
