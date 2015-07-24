module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferenceReflection
          def self.build target, generated_methods, name, options = {}, &block
            reflection = super
            target.attribute(reflection.reference_key, Integer) if target < ActiveData::Model::Attributes
            reflection
          end

          def collection?
            false
          end

          def reference_key
            :"#{name}_id"
          end
        end
      end
    end
  end
end
