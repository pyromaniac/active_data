module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsOne < Base
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

              def build_#{name} attributes = {}
                association(:#{name}).build(attributes)
              end

              def create_#{name} attributes = {}
                association(:#{name}).create(attributes)
              end

              def create_#{name}! attributes = {}
                association(:#{name}).create!(attributes)
              end
            EOS
            reflection
          end

          def alias_association alias_name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              alias_method :#{alias_name}, :#{name}
              alias_method :#{alias_name}=, :#{name}=
              alias_method :build_#{alias_name}, :build_#{name}
              alias_method :create_#{alias_name}, :create_#{name}
              alias_method :create_#{alias_name}!, :create_#{name}!
            RUBY
          end

          def collection?
            false
          end
        end
      end
    end
  end
end
