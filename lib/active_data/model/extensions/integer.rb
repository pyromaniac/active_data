module ActiveData
  module Model
    module Extensions
      module Integer
        extend ActiveSupport::Concern

        def demodelize
          to_s
        end

        module ClassMethods
          def modelize value
            value.try(:to_i) if value.to_s =~ /\A\d+\Z/
          end
        end
      end
    end
  end
end

Integer.send :include, ActiveData::Model::Extensions::Integer
