module ActiveData
  module Model
    module Associations
      class EmbedsOne < Base
        def build attributes = {}
          @target = reflection.klass.new(attributes)
        end

        def create attributes = {}
          @target = reflection.klass.create(attributes)
        end

        def create! attributes = {}
          @target = reflection.klass.create!(attributes)
        end

        def reader
          @target ||= load_target
        end

        def writer value
          raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
          @target = value
        end

      private

        def load_target
          data = owner.read_attribute reflection.name
          reflection.klass.instantiate data if data
        end
      end
    end
  end
end
