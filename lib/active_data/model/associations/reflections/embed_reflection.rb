module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedReflection < Base
          def self.build(target, generated_methods, name, options = {}, &block)
            if block
              options[:class] = proc do |reflection|
                superclass = reflection.options[:class_name].to_s.presence.try(:constantize)
                klass = Class.new(superclass || Object) do
                  include ActiveData::Model
                  include ActiveData::Model::Associations
                  include ActiveData::Model::Lifecycle
                  include ActiveData::Model::Primary
                end
                target.const_set(name.to_s.classify, klass)
                klass.class_eval(&block)
                klass
              end
            end
            super
          end

          def klass
            @klass ||= if options[:class]
              options[:class].call(self)
            else
              super
            end
          end

          def inspect
            "#{self.class.name.demodulize}(#{klass})"
          end
        end
      end
    end
  end
end
