module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferencesAny
          def self.build(target, generated_methods, name, *args, &block)
            reflection = super

            target.add_attribute(
              ActiveData::Model::Attributes::Reflections::ReferenceOne,
              reflection.reference_key, association: name
            )

            reflection
          end

          def self.generate_methods(name, target)
            super

            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def build_#{name} attributes = {}
                association(:#{name}).build(attributes)
              end

              def create_#{name} attributes = {}
                association(:#{name}).create(attributes)
              end

              def create_#{name}! attributes = {}
                association(:#{name}).create!(attributes)
              end
            RUBY
          end

          def collection?
            false
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name}_#{primary_key}"
          end
        end
      end
    end
  end
end
