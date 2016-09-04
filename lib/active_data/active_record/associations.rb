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
        { embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne }.each do |(method, reflection_class)|
          define_singleton_method method do |name, options = {}, &block|
            reflection = reflection_class.build(self, self, name, options.reverse_merge(
              read: ->(ref, object) do
                value = object.read_attribute(ref.name)
                JSON.parse(value) if value.present?
              end,
              write: ->(ref, object, value) do
                object.send(:write_attribute, ref.name, value ? value.to_json : nil)
              end
            ), &block)
            if ::ActiveRecord::Reflection.respond_to? :add_reflection
              ::ActiveRecord::Reflection.add_reflection self, reflection.name, reflection
            else
              self.reflections = reflections.merge(reflection.name => reflection)
            end

            callback_name = :"update_#{reflection.name}_association"
            before_save callback_name
            class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{callback_name}
                association(:#{reflection.name}).apply_changes!
              end
            METHOD
          end
        end
      end
    end
  end
end
