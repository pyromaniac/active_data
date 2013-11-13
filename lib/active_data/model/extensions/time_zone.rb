require 'tzinfo'

module ActiveData
  module Model
    module Extensions
      module TimeZone
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            case value
            when ActiveSupport::TimeZone
              value
            when TZInfo::Timezone
              ActiveSupport::TimeZone[value.name]
            when String, Numeric, ActiveSupport::Duration
              value = Float(value) rescue value
              ActiveSupport::TimeZone[value]
            else
              nil
            end
          end
        end
      end
    end
  end
end

ActiveSupport::TimeZone.send :include, ActiveData::Model::Extensions::TimeZone
