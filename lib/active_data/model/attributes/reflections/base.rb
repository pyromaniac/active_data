module ActiveData
  module Model
    module Attributes
      module Reflections
        class Base
          attr_reader :name, :options
          class << self
            def build_instance target, generated_methods, name, *args, &block
              options = args.extract_options!
              options.merge!(type: args.first) if args.first
              options.merge!(default: block) if block
              new(name, options)
            end

            alias_method :build, :build_instance
            private :build_instance

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

          def build_attribute owner, raw_value = nil
            attribute = self.class.attribute_class.new(owner, self)
            attribute.write(raw_value) if raw_value
            attribute
          end

          def type
            @type ||= options[:type].is_a?(Class) ? options[:type] :
              options[:type].present? ? options[:type].to_s.camelize.constantize : Object
          end

          def inspect_reflection
            "#{name}: #{type}"
          end
        end
      end
    end
  end
end
