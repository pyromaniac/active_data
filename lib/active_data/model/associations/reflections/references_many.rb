require 'active_data/model/associations/reflections/base'

module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesMany < Base
          def macro
            :references_many
          end

          def collection?
            true
          end

          def association_class
            ActiveData::Model::Associations::ReferencesMany
          end

          def read_source object
            value = object.read_attribute(reference_key)
            value
          end

          def write_source object, value
            object.write_attribute(reference_key, value)
          end

          def reference_key
            :"#{name.to_s.singularize}_ids"
          end

          def association_primary_key
            :id
          end

          def attributes
            {reference_key => {type: Integer, mode: :collection}}
          end

          private

          def define_methods!
            owner.class_eval <<-EOS
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end
            EOS
          end
        end
      end
    end
  end
end
