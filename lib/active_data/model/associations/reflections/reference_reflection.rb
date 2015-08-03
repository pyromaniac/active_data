module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferenceReflection < Base
          def self.build target, generated_methods, name, *args, &block
            reflection = new(name, *args)
            generated_methods.class_eval <<-EOS
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end
            EOS
            reflection
          end

          def initialize name, *args
            @options = args.extract_options!
            @scope_proc = args.first
            @name = name.to_sym
          end

          def read_source object
            object.read_attribute(reference_key)
          end

          def write_source object, value
            object.write_attribute(reference_key, value)
          end

          def primary_key
            @primary_key ||= options[:primary_key].presence.try(:to_sym) || :id
          end

          def scope
            @scope ||= begin
              scope = klass.unscoped
              scope = scope.instance_exec(&@scope_proc) if @scope_proc
              scope
            end
          end
        end
      end
    end
  end
end
