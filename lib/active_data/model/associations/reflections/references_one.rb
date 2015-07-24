module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferenceReflection
          def collection?
            false
          end

          def association_class
            ActiveData::Model::Associations::ReferencesOne
          end

          def reference_key
            :"#{name}_id"
          end

        private
          def define_methods!
            owner.attribute(reference_key, Integer) if owner < ActiveData::Model::Attributes
            super
          end
        end
      end
    end
  end
end
