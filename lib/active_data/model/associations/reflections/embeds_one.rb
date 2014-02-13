module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsOne < Base

          def collection?
            false
          end

          def builder_class
            ActiveData::Model::Associations::Builders::EmbedsOne
          end

          def define_methods target
            target.class_eval <<-EOS
              def #{name}
                association(:#{name}).target
              end

              def #{name}= value
                association(:#{name}).assign(value)
              end

              def build_#{name} attributes = {}
                association(:#{name}).build(attributes)
              end

              def create_#{name} attributes = {}
                association(:#{name}).create(attributes)
              end
            EOS
          end

        end
      end
    end
  end
end
