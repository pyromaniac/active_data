module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesMany < ReferenceReflection
          def self.build target, generated_methods, name, options = {}, &block
            reflection = super
            target.collection(reflection.reference_key, Integer) if target < ActiveData::Model::Attributes
            reflection
          end

          def collection?
            true
          end

          def reference_key
            :"#{name.to_s.singularize}_ids"
          end
        end
      end
    end
  end
end
