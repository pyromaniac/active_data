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
            if identifier = object.read_attribute(association_foreign_key)
              klass.find(identifier)
            end
          end

          def write_source object, value
            identifier = value && value.send(association_primary_key)
            object.write_attribute(association_foreign_key, identifier.presence)
            true
          end

          private

          def association_foreign_key
            :"#{name}_id"
          end

          def association_primary_key
            :id
          end

          def define_methods!
            owner.class_eval <<-EOS
              attribute(:#{association_foreign_key}, Integer) unless has_attribute?(:#{association_foreign_key})

              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end

              def #{association_foreign_key}
                if association(:#{name}).loaded?
                  association(:#{name}).target.try(:#{association_primary_key})
                else
                  super
                end
              end

              def #{association_foreign_key}= value
                super.tap { association(:#{name}).reset }
              end
            EOS
          end
        end
      end
    end
  end
end
