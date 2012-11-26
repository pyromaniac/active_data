module ActiveData
  module Model
    module Extensions
      module Float
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.try(:to_f) if value.to_s =~ /\A\d+(?:\.\d*)?\Z/
          end
        end
      end
    end
  end
end

Float.send :include, ActiveData::Model::Extensions::Float
