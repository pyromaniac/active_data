require 'active_data/model/associations/reflections/reference_reflection'

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

          def attributes
            {reference_key => {type: Integer}}
          end
        end
      end
    end
  end
end
