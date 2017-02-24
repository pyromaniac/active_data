require 'active_data/model/attributes/reflections/reference_many'
require 'active_data/model/attributes/reference_many'

module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesMany < ReferencesAny
          def self.build(target, generated_methods, name, *args, &block)
            reflection = super

            target.add_attribute(
              ActiveData::Model::Attributes::Reflections::ReferenceMany,
              reflection.reference_key, association: name
            )

            reflection
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name.to_s.singularize}_#{primary_key.to_s.pluralize}"
          end
        end
      end
    end
  end
end
