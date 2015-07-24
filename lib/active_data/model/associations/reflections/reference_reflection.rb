module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferenceReflection < Base
          def read_source object
            object.read_attribute(reference_key)
          end

          def write_source object, value
            object.write_attribute(reference_key, value)
          end

          def reference_key
            raise NotImplementedError
          end

          def primary_key
            :id
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
