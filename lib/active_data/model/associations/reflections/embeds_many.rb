module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsMany < Base
          def self.build target, generated_methods, name, options = {}, &block
            if target < ActiveData::Model::Attributes
              target.add_attribute(ActiveData::Model::Attributes::Reflections::Base, name)
            end
            super
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
