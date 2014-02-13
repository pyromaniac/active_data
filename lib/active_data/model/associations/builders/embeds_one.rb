module ActiveData
  module Model
    module Associations
      module Builders
        class EmbedsOne < Base
          def target
            @target
          end

          def build attributes = {}
            @target = reflection.klass.new(attributes)
          end

          def create attributes = {}
            @target = reflection.klass.create(attributes)
          end

          def assign value
            raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
            @target = value
          end
        end
      end
    end
  end
end
