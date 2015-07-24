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

        private

          def define_methods!
            owner.add_attribute(ActiveData::Model::Attributes::Reflections::Association, name) if owner < ActiveData::Model::Attributes
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
