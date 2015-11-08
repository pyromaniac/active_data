module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferenceReflection
          def self.build target, generated_methods, name, *args, &block
            reflection = super

            reference = target.reflect_on_attribute(reflection.reference_key) ||
              target.attribute(reflection.reference_key, Integer)
            default = reflection.reference_default
            reference.options[:default] = default if default

            reflection
          end

          def collection?
            false
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name}_#{primary_key}"
          end

          def reference_default
            if options[:default]
              class_eval <<-PROC
                lambda { association(:#{name}).default }
              PROC
            end
          end
        end
      end
    end
  end
end
