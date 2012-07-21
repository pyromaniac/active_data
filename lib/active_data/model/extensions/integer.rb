module ActiveData
  module Model
    module Extensions
      module Integer
        extend ActiveSupport::Concern

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
