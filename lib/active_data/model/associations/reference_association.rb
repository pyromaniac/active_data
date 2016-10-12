module ActiveData
  module Model
    module Associations
      class ReferenceAssociation < Base
        def scope(source = read_source)
          reflection.persistence_adapter.scope(owner, source)
        end

      private

        def build_object(attributes)
          reflection.klass.new(attributes)
        end
      end
    end
  end
end
