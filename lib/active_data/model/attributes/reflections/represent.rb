module ActiveData
  module Model
    module Attributes
      module Reflections
        class Represent < Attribute
          def initialize name, options
            super
            raise ArgumentError, "Undefined reference for `#{name}`" if reference.blank?
          end

          def type
            Object
          end

          def reference
            @reference ||= options[:of].to_s
          end

          def attribute
            @attribute ||= options[:attribute].presence.try(:to_s) || name
          end

          def reader
            @reader ||= options[:reader].presence.try(:to_s) || attribute
          end

          def reader_before_type_cast
            @reader_before_type_cast ||= "#{reader}_before_type_cast"
          end

          def writer
            @writer ||= "#{options[:writer].presence || attribute}="
          end

          def inspect_reflection
            "#{name}: (represent)"
          end

        private

          def build_instance target, name, *args, &block
            options = args.extract_options!
            options.merge!(default: block) if block
            new(name, options)
          end
        end
      end
    end
  end
end
