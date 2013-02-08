module ActiveData
  module Model
    module Extensions
      module Localized
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            case value
            when ::Hash then
              value.stringify_keys!
            else
              nil
            end
          end
        end
      end
    end
  end
end

Localized.send :include, ActiveData::Model::Extensions::Localized
