module ActiveData
  module Model
    module Extensions
      module String
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.to_s if value.present?
          end
        end
      end
    end
  end
end

String.send :include, ActiveData::Model::Extensions::String
