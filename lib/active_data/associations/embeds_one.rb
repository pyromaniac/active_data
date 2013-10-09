module ActiveData
  module Associations
    class EmbedsOne
      attr_accessor :reflection, :owner, :target

      def initialize owner, reflection
        @owner, @reflection = owner, reflection
      end

      def build attributes = {}
        self.target = reflection.klass.new attributes
      end

      def assign value
        raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
        self.target = value
      end
    end
  end
end
