module ActiveData
  module Model
    module Associations
      class Many
        attr_reader :name, :klass, :options

        def initialize name, options = {}
          @name, @options = name.to_s, options
          @klass ||= options[:class] || (options[:class_name].to_s.presence || name.to_s.classify).safe_constantize
          raise "Can not determine class for `#{name}` association" unless @klass
        end

        def class_name
          klass.to_s
        end

        def collection?
          true
        end

      end
    end
  end
end