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
            generate_methods name, generated_methods
            reflection
          end

          def self.generate_methods name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
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
            RUBY
          end

          def initialize name, options = {}
            super
            options[:validate] = true unless options.key?(:validate)
          end

          def collection?
            false
          end

          def embedded?
            true
          end
        end
      end
    end
  end
end
