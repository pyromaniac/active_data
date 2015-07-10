require 'active_data/model/associations/reflections/reference_reflection'

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

          def attributes
            {reference_key => {type: Integer, mode: :collection}}
          end
        end
      end
    end
  end
end
