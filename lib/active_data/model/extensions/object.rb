module ActiveData
  module Model
    module Extensions
      module Object
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value
          end
        end
      end
    end
  end
end

Object.send :include, ActiveData::Model::Extensions::Object
