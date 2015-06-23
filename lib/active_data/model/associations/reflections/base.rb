module ActiveData
  module Model
    module Associations
      module Reflections
        class Base
          READ = ->(reflection, object) { object.read_attribute reflection.name }
          WRITE = ->(reflection, object, value) { object.write_attribute reflection.name, value }

          attr_reader :owner, :name, :options, :evaluator
          attr_accessor :parent_reflection

          def initialize owner, name, options = {}, &block
            @owner, @name, @options, @evaluator = owner, name.to_sym, options, block
            define_methods!
          end

          def klass
            @klass ||= if evaluator
              superclass = options[:class_name].to_s.presence.try(:safe_constantize)
              raise "Can not determine superclass for `#{owner}##{name}` association" if options[:class_name].present? && !superclass
              klass = Class.new(superclass || Object) do
                include ActiveData::Model
                include ActiveData::Model::Lifecycle
              end
              owner.const_set(name.to_s.classify, klass)
              klass.class_eval(&evaluator)
              klass
            else
              klass = class_name.safe_constantize or raise "Can not determine class for `#{owner}##{name}` association"
            end
          end

          def class_name
            @class_name ||= (options[:class_name].presence || name.to_s.classify).to_s
          end

          def validate?
            false
          end

          def belongs_to?
            false
          end

          def build_association object
            association_class.new object, self
          end

          def read_source object
            (options[:read] || READ).call(self, object)
          end

          def write_source object, value
            (options[:write] || WRITE).call(self, object, value)
          end

        private

          def define_methods!
            raise NotImplementedError
          end
        end
      end
    end
  end
end
