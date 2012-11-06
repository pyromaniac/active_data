module ActiveData
  module Model
    module Extensions
      module String
        extend ActiveSupport::Concern

        def demodelize
          self
        end

        module ClassMethods
          def modelize value
            value.to_s if value.present?
          end
        end
      end
    end
  end
end

String.send :include, ActiveData::Model::Extensions::String
