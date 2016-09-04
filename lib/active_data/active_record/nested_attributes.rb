module ActiveData
  module ActiveRecord
    module NestedAttributes
      extend ActiveSupport::Concern

      included do
        singleton_class.alias_method_chain :accepts_nested_attributes_for, :active_data
      end

      module ClassMethods
        def accepts_nested_attributes_for_with_active_data(*attr_names)
          options = attr_names.extract_options!
          active_data_associations, active_record_association = attr_names.partition do |association_name|
            reflect_on_association(association_name).is_a?(ActiveData::Model::Associations::Reflections::Base)
          end

          ActiveData::Model::Associations::NestedAttributes::NestedAttributesMethods
            .accepts_nested_attributes_for(self, *active_data_associations, options.dup)
          accepts_nested_attributes_for_without_active_data(*active_record_association, options.dup)
        end
      end
    end
  end
end
