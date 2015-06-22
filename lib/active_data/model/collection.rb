module ActiveData
  module Model
    module Collection
      extend ActiveSupport::Concern

      included do
        class_attribute :_collection_superclass
        collectionize
      end

      module Proxy
        extend ActiveSupport::Concern

        included do
          class_attribute :collectible

          def initialize source = nil, trust = false
            source ||= self.class.superclass.new

            source.each do |entity|
              raise AssociationTypeMismatch.new(collectible, entity.class) unless entity.is_a?(collectible)
            end unless trust && source.is_a?(self.class)

            super source
          end
        end

        def respond_to_missing? method, _
          super || collectible.respond_to?(method)
        end

        def method_missing method, *args, &block
          with_scope { collectible.send(method, *args, &block) }
        end

        def with_scope
          previous_scope = collectible.current_scope
          collectible.current_scope = self
          result = yield
          collectible.current_scope = previous_scope
          result
        end
      end

      module ClassMethods
        def collectionize collection_superclass = Array
          self._collection_superclass = collection_superclass
        end

        def collection_class
          @collection_class ||= begin
            Class.new(_collection_superclass) do
              include ActiveData::Model::Collection::Proxy
            end.tap { |klass| klass.collectible = self }
          end
        end

        def collection source = nil, trust = false
          collection_class.new source, trust
        end

        def respond_to_missing? method, include_private
          super || collection_class.superclass.method_defined?(method)
        end

        def method_missing method, *args, &block
          collection_class.superclass.method_defined?(method) ?
            current_scope.send(method, *args, &block) :
            super
        end

        def current_scope= value
          @current_scope = value
        end

        def current_scope
          @current_scope ||= collection
        end
        alias :scope :current_scope
      end
    end
  end
end
