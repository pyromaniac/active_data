module ActiveData
  module Model
    module Extensions
      module Time
        extend ActiveSupport::Concern

        module ClassMethods
          def active_data_type_cast value
            return ::Time.at(value.to_i).utc if value.to_s =~ /\A\d{10,11}\Z/
            value.to_time rescue nil
          end
        end
      end
    end
  end
end

Time.send :include, ActiveData::Model::Extensions::Time
