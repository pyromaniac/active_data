module ActiveData
  module Model
    module Extensions
      module Integer
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            Float(value).to_i rescue nil if value
          end
        end
      end
    end
  end
end

Integer.send :include, ActiveData::Model::Extensions::Integer
