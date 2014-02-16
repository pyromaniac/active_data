module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsMany < Base

          def collection?
            true
          end

          def association_class
            ActiveData::Model::Associations::EmbedsMany
          end

          def define_methods target
            target.class_eval <<-EOS
              def #{name}
                association(:#{name}).reader
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
