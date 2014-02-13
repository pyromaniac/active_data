module ActiveData
  module Model
    module Associations
      module Reflections
        class Base
          attr_reader :name, :options

          def initialize name, options = {}
            @name, @options = name.to_sym, options
          end

          def klass
            @klass ||= begin
              klass = (options[:class_name].presence || name.to_s.classify).safe_constantize
              raise "Can not determine class for `#{name}` association" unless klass
              klass
            end
          end

          def class_name
            klass.to_s
          end

          def builder owner
            builder_class.new owner, self
          end
        end
      end
    end
  end
end
