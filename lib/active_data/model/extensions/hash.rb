module ActiveData
  module Model
    module Extensions
      module Hash
        extend ActiveSupport::Concern

        def demodelize
          nil
        end

        module ClassMethods
          def modelize value
            case value
            when Hash then
              value
            else
              nil
            end
          end
        end
      end
    end
  end
end

Hash.send :include, ActiveData::Model::Extensions::Hash
