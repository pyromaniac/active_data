module ActiveData
  module Model
    module Extensions
      module Integer
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            value.try(:to_i) if value.to_s =~ /\A\d+(?:\.\d*)?\Z/
          end
        end
      end
    end
  end
end

Integer.send :include, ActiveData::Model::Extensions::Integer
