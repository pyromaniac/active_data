module ActiveData
  module Model
    module Associations
      class EmbedsOne < Base
        def load_target
          data = owner.read_attribute reflection.name
          reflection.klass.instantiate data if data
        end

        def target= value
          @target = value
        end

        def target
          @target ||= load_target
        end

        def build attributes = {}
          @target = reflection.klass.new(attributes)
        end

        def create attributes = {}
          @target = reflection.klass.create(attributes)
        end

        def assign value
          raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
          self.target = value
        end
      end
    end
  end
end
