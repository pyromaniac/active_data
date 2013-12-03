module ActiveData
  module Associations
    module Builders
      class EmbedsMany < Base
        class Proxy < Array
          delegate :build, to: :@association

          def initialize(data, association)
            @association = association
            super(data)
          end
        end

        def target= value
          @target = Proxy.new value, self
        end

        def target
          @target ||= Proxy.new [], self
        end

        def build attributes = {}
          target.push(reflection.klass.new(attributes)).last
        end

        def assign values
          values = Array.wrap(values)
          values.each do |value|
            raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
          end
          self.target = values
        end
      end
    end
  end
end
