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
            generate_methods name, generated_methods
            reflection
          end

          def initialize name, options = {}
            super
            options[:validate] = true unless options.key?(:validate)
          end

          def collection?
            true
          end

          def embedded?
            true
          end
        end
      end
    end
  end
end
