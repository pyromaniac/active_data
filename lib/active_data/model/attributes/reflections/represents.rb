module ActiveData
  module Model
    module Attributes
      module Reflections
        class Represents < Attribute
          def self.build target, generated_methods, name, *args, &block
            options = args.extract_options!
            reference = target.reflect_on_association(options[:of]) if target.respond_to?(:reflect_on_association)
            reference ||= target.reflect_on_attribute(options[:of]) if target.respond_to?(:reflect_on_attribute)
            if reference
              options[:of] = reference.name
              reference.options[:validate] = true
              reference.options[:flush_represents_of] = reference.name
              if reference.respond_to?(:reference_key)
                reference_key = target.reflect_on_attribute(reference.reference_key)
                reference_key.options[:flush_represents_of] = reference.name
              end
            end
            super target, generated_methods, name, *args, options, &block
          end

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
            "#{name}: (represents)"
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
