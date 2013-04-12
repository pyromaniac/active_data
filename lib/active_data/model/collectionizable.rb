require 'active_data/model/collectionizable/proxy'

module ActiveData
  module Model
    module Collectionizable
      extend ActiveSupport::Concern

      included do
        collectionize
      end

      module ClassMethods

        def collectionize collection_superclass = Array
          collection_class = Class.new(collection_superclass) do
            include ActiveData::Model::Collectionizable::Proxy
          end
          collection_class.collectible = self

          @collection_class = collection_class
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
          @collection_class
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
