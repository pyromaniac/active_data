module ActiveData
  module Model
    module Associations
      module Reflections
        class Base
          attr_reader :name, :klass, :options

          def initialize name, options = {}
            @name, @options = name.to_sym, options
            @klass ||= options[:class] || (options[:class_name].to_s.presence || name.to_s.classify).safe_constantize
            raise "Can not determine class for `#{name}` association" unless @klass
          end

          def class_name
            klass.to_s
          end

          def define_accessor klass
            define_reader klass
            define_writer klass
          end

          def define_reader klass
          end

          def define_writer klass
          end
        end
      end
    end
  end
end