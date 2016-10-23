module ActiveData
  module Model
    module Associations
      class EmbedsAny < Base
      private

        def build_object(attributes)
          reflection.klass.new(attributes)
        end

        def embed_object(object)
          object.instance_variable_set(:@embedder, owner)
        end
      end
    end
  end
end
