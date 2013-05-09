module ActiveData
  module Model
    module Extensions
      module Date
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.to_date rescue nil
          end
        end
      end
    end
  end
end

Date.send :include, ActiveData::Model::Extensions::Date
