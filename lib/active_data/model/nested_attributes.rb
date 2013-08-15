module ActiveData
  module Model
    module NestedAttributes
      extend ActiveSupport::Concern

      module ClassMethods

        def nested_attributes? association_name
          method_defined?(:"#{association_name}_attributes=")
        end

        def accepts_nested_attributes_for *attr_names
          attr_names.each do |association_name|
            reflection = reflect_on_association association_name
            type = (reflection.collection? ? :collection : :one_to_one)

            class_eval <<-EOS, __FILE__, __LINE__ + 1
              if method_defined?(:#{association_name}_attributes=)
                remove_method(:#{association_name}_attributes=)
              end
              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
              end
            EOS
          end
        end

      end

      def assign_nested_attributes_for_collection_association(association_name, attributes_collection, assignment_opts = {})
        unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
          raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
        end

        if attributes_collection.is_a? Hash
          keys = attributes_collection.keys
          attributes_collection = if keys.include?('id') || keys.include?(:id)
            Array.wrap(attributes_collection)
          else
            attributes_collection.values
          end
        end

        reflection = self.class.reflect_on_association association_name

        send "#{association_name}=", attributes_collection.map { |attrs| reflection.klass.new attrs }
      end

      def assign_nested_attributes_for_one_to_one_association(association_name, attributes, assignment_opts = {})
        unless attributes.is_a?(Hash)
          raise ArgumentError, "Hash expected, got #{attributes.class.name} (#{attributes.inspect})"
        end

        reflection = self.class.reflect_on_association association_name

        send "#{association_name}=", reflection.klass.new(attributes)
      end
    end
  end
end
