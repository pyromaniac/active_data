module ActiveData
  module ActiveRecord
    module Associations
      module Reflections
        class EmbedsOne < ActiveData::Model::Associations::Reflections::EmbedsOne
          def is_a? klass
            super || klass == ::ActiveRecord::Reflection::AssociationReflection
          end
        end

        class EmbedsMany < ActiveData::Model::Associations::Reflections::EmbedsMany
          def is_a? klass
            super || klass == ::ActiveRecord::Reflection::AssociationReflection
          end
        end
      end

      extend ActiveSupport::Concern

      included do
        {embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne}.each do |(name, reflection_class)|
          define_singleton_method name do |name, options = {}|
            reflection = reflection_class.new(name, options.reverse_merge(
              read: ->(reflection, object) {
                value = object.read_attribute(reflection.name)
                JSON.parse(value) if value.present?
              },
              write: ->(reflection, object, value) {
                object.send(:write_attribute, reflection.name, value.to_json)
              }
            ))
            reflection.define_methods self
            self.reflections = reflections.merge(reflection.name => reflection)
          end
        end
      end
    end
  end
end
