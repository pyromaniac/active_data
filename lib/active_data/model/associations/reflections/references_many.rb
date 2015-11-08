module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesMany < ReferenceReflection
          def self.build target, generated_methods, name, *args, &block
            reflection = super

            reference = target.reflect_on_attribute(reflection.reference_key) ||
              target.collection(reflection.reference_key, Integer)
            normalizer = reflection.reference_normalizer
            reference.options[:normalizer] = normalizer if normalizer

            reflection
          end

          def collection?
            true
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name.to_s.singularize}_#{primary_key.to_s.pluralize}"
          end

          def reference_normalizer
            if options[:default]
              class_eval <<-PROC
                lambda { |value| value.presence || association(:#{name}).default }
              PROC
            end
          end
        end
      end
    end
  end
end
