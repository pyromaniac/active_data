require 'active_data/model/associations/reflections/base'

module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < Base
          def macro
            :references_one
          end

          def collection?
            false
          end

          def association_class
            ActiveData::Model::Associations::ReferencesOne
          end

          def read_source object
            object.read_attribute(reference_key)
          end

          def write_source object, value
            object.write_attribute(reference_key, value)
          end

          def reference_key
            :"#{name}_id"
          end

          def association_primary_key
            :id
          end

          private

          def define_methods!
            owner.class_eval <<-EOS
              attribute :#{reference_key}, Integer

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
