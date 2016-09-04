module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferenceReflection
          def self.build(target, generated_methods, name, *args, &block)
            reflection = super

            target.add_attribute(
              ActiveData::Model::Attributes::Reflections::ReferenceOne,
              reflection.reference_key, association: name)

            reflection
          end

          def collection?
            false
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
