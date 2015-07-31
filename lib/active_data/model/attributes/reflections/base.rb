module ActiveData
  module Model
    module Attributes
      module Reflections
        class Base
          attr_reader :name, :options
          class << self
            def build_instance target, name, *args, &block
              options = args.extract_options!
              options.merge!(type: args.first) if args.first
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

          def build_attribute owner, raw_value
            self.class.attribute_class.new(owner, self).tap { |a| a.write(raw_value) }
          end

          def type
            @type ||= options[:type].is_a?(Class) ? options[:type] :
              options[:type].present? ? options[:type].to_s.camelize.constantize : Object
          end
        end
      end
    end
  end
end
