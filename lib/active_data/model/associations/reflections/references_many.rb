module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesMany < ReferenceReflection
          def collection?
            true
          end

          def association_class
            ActiveData::Model::Associations::ReferencesMany
          end

          def reference_key
            :"#{name.to_s.singularize}_ids"
          end

        private

          def define_methods!
            owner.collection(reference_key, Integer) if owner < ActiveData::Model::Attributes
            super
          end
        end
      end
    end
  end
end
