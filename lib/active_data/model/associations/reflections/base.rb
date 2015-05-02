module ActiveData
  module Model
    module Associations
      module Reflections
        class Base
          READ = ->(reflection, object) { object.read_attribute reflection.name }
          WRITE = ->(reflection, object, value) { object.write_attribute reflection.name, value }

          attr_reader :name, :options
          attr_accessor :parent_reflection

          def initialize name, options = {}
            @name, @options = name.to_sym, options
          end

          def klass
            @klass ||= begin
              klass = class_name.safe_constantize
              raise "Can not determine class for `#{name}` association" unless klass
              klass
            end
          end

          def validate?
            false
          end

          def belongs_to?
            false
          end

          def class_name
            @class_name ||= (options[:class_name].presence || name.to_s.classify).to_s
          end

          def build_association owner
            association_class.new owner, self
          end

          def read_source object
            (options[:read] || READ).call(self, object)
          end

          def write_source object, value
            (options[:write] || WRITE).call(self, object, value)
          end
        end
      end
    end
  end
end
