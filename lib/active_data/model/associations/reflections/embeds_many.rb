module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsMany < Base
          def self.build target, generated_methods, name, options = {}, &block
            reflection = super
            if target < ActiveData::Model::Attributes
              target.add_attribute(ActiveData::Model::Attributes::Reflections::Base, name)
            end
            generated_methods.class_eval <<-EOS
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end
            EOS
            reflection
          end

          def collection?
            true
          end
        end
      end
    end
  end
end
