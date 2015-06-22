module ActiveData
  module Model
    module Extensions
      module Time
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.is_a?(String) && ::Time.zone ? ::Time.zone.parse(value) : value.try(:to_time)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end

Time.send :include, ActiveData::Model::Extensions::Time
