module ActiveData
  module Model
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods
        def instantiate(data)
          data = data.stringify_keys
          instance = allocate

          instance.instance_variable_set(:@initial_attributes, data.slice(*attribute_names))
          instance.send(:mark_persisted!)

          instance
        end

        def instantiate_collection(data)
          collection = Array.wrap(data).map { |attrs| instantiate attrs }
          collection = scope(collection, true) if respond_to?(:scope)
          collection
        end
      end

      def persisted?
        !!@persisted
      end

      def destroyed?
        !!@destroyed
      end

      def marked_for_destruction?
        @marked_for_destruction
      end

      def mark_for_destruction
        @marked_for_destruction = true
      end

      def _destroy
        marked_for_destruction?
      end

    private

      def mark_persisted!
        @persisted = true
        @destroyed = false
      end

      def mark_destroyed!
        @persisted = false
        @destroyed = true
      end
    end
  end
end
