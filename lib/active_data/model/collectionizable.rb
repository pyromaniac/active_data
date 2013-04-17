require 'active_data/model/collectionizable/proxy'

module ActiveData
  module Model
    module Collectionizable
      extend ActiveSupport::Concern

      included do
        class_attribute :_collection_superclass
        collectionize
      end

      module ClassMethods

        def collectionize collection_superclass = Array
          self._collection_superclass = collection_superclass
        end

        def respond_to_missing? method, include_private
          super || collection_class.superclass.method_defined?(method)
        end

        def method_missing method, *args, &block
          collection_class.superclass.method_defined?(method) ?
            current_scope.send(method, *args, &block) :
            super
        end

        def collection source = nil
          collection_class.new source
        end

        def collection_class
          @collection_class ||= begin
            Class.new(_collection_superclass) do
              include ActiveData::Model::Collectionizable::Proxy
            end.tap { |klass| klass.collectible = self }
          end
        end

        def current_scope= value
          @current_scope = value
        end

        def current_scope
          @current_scope ||= collection(load)
        end
        alias :scope :current_scope

        def load; end

      end
    end
  end
end
