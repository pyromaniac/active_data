require 'active_data/model/attributes/reflections/reference_one'
require 'active_data/model/attributes/reference_one'

module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferencesAny
          include Singular

          def self.build(target, generated_methods, name, *args, &block)
            reflection = super

            target.add_attribute(
              ActiveData::Model::Attributes::Reflections::ReferenceOne,
              reflection.reference_key, association: name
            )

            reflection
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name}_#{primary_key}"
          end
        end
      end
    end
  end
end
