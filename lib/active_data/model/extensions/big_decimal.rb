 module ActiveData
  module Model
    module Extensions
      module BigDecimal
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            ::BigDecimal.new Float(value).to_s rescue nil if value
          end
        end
      end
    end
  end
end

BigDecimal.send :include, ActiveData::Model::Extensions::BigDecimal
