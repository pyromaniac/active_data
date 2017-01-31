module ActiveData
  module ActiveRecord
    module NestedAttributes
      extend ActiveSupport::Concern

      def accepts_nested_attributes_for(*attr_names)
        options = attr_names.extract_options!
        active_data_associations, active_record_association = attr_names.partition do |association_name|
          reflect_on_association(association_name).is_a?(ActiveData::Model::Associations::Reflections::Base)
        end

        ActiveData::Model::Associations::NestedAttributes::NestedAttributesMethods
          .accepts_nested_attributes_for(self, *active_data_associations, options.dup)
        super(*active_record_association, options.dup)
      end
    end
  end
end
