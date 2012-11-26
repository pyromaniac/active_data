module ActiveData
  module Model
    module Extensions
      module BigDecimal
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            ::BigDecimal.new value.to_s if value.to_s =~ /\A\d+(?:\.\d*)?\Z/
          end
        end
      end
    end
  end
end

BigDecimal.send :include, ActiveData::Model::Extensions::BigDecimal
