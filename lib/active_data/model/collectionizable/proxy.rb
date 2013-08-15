module ActiveData
  module Model
    module Collectionizable
      module Proxy
        extend ActiveSupport::Concern

        included do
          class_attribute :collectible

          def initialize source = nil, trust = false
            source ||= self.class.superclass.new

            source.each do |entity|
              raise IncorrectEntity.new(collectible, entity.class) unless entity.is_a?(collectible)
            end unless trust && source.is_a?(self.class)

            super source
          end
        end

        def respond_to_missing? method
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
    end
  end
end
