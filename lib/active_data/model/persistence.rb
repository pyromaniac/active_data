module ActiveData
  module Model
    module Persistence
      extend ActiveSupport::Concern

      included do
        include Collection

        alias_method_chain :initialize, :persistence
      end

      module ClassMethods
        def instantiate data
          data = data.stringify_keys
          instance = allocate

          attributes = initialize_attributes
          attributes.merge!(data.slice(*attributes.keys))

          instance.instance_variable_set(:@attributes, attributes)
          instance.instance_variable_set(:@persisted, true)
          instance.instance_variable_set(:@destroyed, false)

          instance
        end

        def instantiate_collection data
          collection(Array.wrap(data).map { |attrs| instantiate attrs }, true)
        end
      end

      def initialize_with_persistence *_, &block
        @persisted = false
        @destroyed = false
        initialize_without_persistence *_, &block
      end

      def persisted?
        @persisted
      end

      def destroyed?
        @destroyed
      end
    end
  end
end
