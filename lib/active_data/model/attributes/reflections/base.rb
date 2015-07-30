module ActiveData
  module Model
    module Attributes
      module Reflections
        class Base
          attr_reader :name, :options

          def self.build target, name, *args, &block
            options = args.extract_options!
            options.merge!(type: args.first) if args.first
            options.merge!(default: block) if block
            new(name, options)
          end

          def self.attribute_class
            @attribute_class ||= "ActiveData::Model::Attributes::#{name.demodulize}".constantize
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

          def defaultizer
            @defaultizer ||= options[:default]
          end

          def typecaster
            @typecaster ||= ActiveData.typecaster(type.ancestors.grep(Class))
          end

          def enumerizer
            @enumerizer ||= options[:enum] || options[:in]
          end

          def normalizers
            @normalizers ||= Array.wrap(options[:normalize] || options[:normalizer] || options[:normalizers])
          end
        end
      end
    end
  end
end
