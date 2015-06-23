module ActiveData
  module Model
    module Persistence
      extend ActiveSupport::Concern

      included do
        include Scopes
      end

      module ClassMethods
        def instantiate data
          data = data.stringify_keys
          instance = allocate

          attributes = initialize_attributes
          attributes.merge!(data.slice(*attributes.keys))

          instance.instance_variable_set(:@attributes, attributes)
          instance.send(:mark_persisted!)

          instance
        end

        def instantiate_collection data
          scope(Array.wrap(data).map { |attrs| instantiate attrs }, true)
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
