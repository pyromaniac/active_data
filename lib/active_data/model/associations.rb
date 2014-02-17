module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        include NestedAttributes

        class_attribute :reflections, instance_reader: false, instance_writer: false
        self.reflections = {}

        { embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne }.each do |(name, reflection_class)|
          define_singleton_method name do |*args|
            reflection = reflection_class.new *args
            attribute reflection.name, mode: :association
            reflection.define_methods self
            self.reflections = reflections.merge(reflection.name => reflection)
          end
        end
      end

      module ClassMethods
        def reflect_on_association name
          reflections[name.to_sym]
        end
      end

      def association name
        @_associations ||= {}
        @_associations[name.to_sym] ||= self.class.reflect_on_association(name).build_association(self)
      end

      def == other
        super(other) && self.class.reflections.keys.all? do |association|
          public_send(association) == other.public_send(association)
        end
      end
    end
  end
end
