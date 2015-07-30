module ActiveData
  module Model
    module Attributes
      module Reflections
        class Base
          attr_reader :name, :options
          class << self
            def build_reflection target, name, *args, &block
              options = args.extract_options!
              new(name, options)
            end

            alias_method :build, :build_reflection
            private :build_reflection

            def attribute_class
              @attribute_class ||= "ActiveData::Model::Attributes::#{name.demodulize}".constantize
            end
          end

          def initialize name, options = {}
            @name = name.to_s
            @options = options
          end

          def alias_attribute alias_name, target
            raise NotImplementedError, 'Attribute aliasing is not supported'
          end

          def build_attribute owner, raw_value
            self.class.attribute_class.new(owner, self).tap { |a| a.write(raw_value) }
          end
        end
      end
    end
  end
end
