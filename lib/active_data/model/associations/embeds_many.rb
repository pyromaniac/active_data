module ActiveData
  module Model
    module Associations
      class EmbedsMany < Base
        class Proxy < Array
          def initialize(data, association)
            @association = association
            super(data)
          end

          def build attributes = {}
            push(@association.reflection.klass.new(attributes)).last
          end

          def create attributes = {}
            push(@association.reflection.klass.create(attributes)).last
          end

          def create! attributes = {}
            push(@association.reflection.klass.create!(attributes)).last
          end
        end

        delegate :build, :create, :create!, to: :target

        def reader
          @target ||= Proxy.new load_target, self
        end

        def writer values
          values ||= []
          values.each do |value|
            raise IncorrectEntity.new(reflection.klass, value.class) if value && !value.is_a?(reflection.klass)
          end
          @target = Proxy.new values, self
        end

      private

        def load_target
          data = owner.read_attribute reflection.name
          data ? reflection.klass.instantiate_collection(data) : []
        end
      end
    end
  end
end
