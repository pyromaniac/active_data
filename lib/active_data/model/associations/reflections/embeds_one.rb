module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsOne < EmbedsAny
          include Singular

          def self.build(target, generated_methods, name, options = {}, &block)
            if target < ActiveData::Model::Attributes
              target.add_attribute(ActiveData::Model::Attributes::Reflections::Base, name)
            end
            options[:validate] = true unless options.key?(:validate)
            super
          end
        end
      end
    end
  end
end
