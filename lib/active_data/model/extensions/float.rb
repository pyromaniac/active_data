module ActiveData
  module Model
    module Extensions
      module Float
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            Float(value) rescue nil if value
          end
        end
      end
    end
  end
end

Float.send :include, ActiveData::Model::Extensions::Float
