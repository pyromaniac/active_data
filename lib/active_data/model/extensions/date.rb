module ActiveData
  module Model
    module Extensions
      module Date
        extend ActiveSupport::Concern

        def demodelize
          to_s
        end

        module ClassMethods
          def modelize value
            case value
            when String then
              Date.parse(value.to_s) rescue nil
            when Date, DateTime, Time then
              value.to_date
            else
              nil
            end
          end
        end
      end
    end
  end
end

Date.send :include, ActiveData::Model::Extensions::Date
