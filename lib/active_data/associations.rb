module ActiveData
  module Associations
    extend ActiveSupport::Concern

    included do
      include NestedAttributes

      class_attribute :_reflections, instance_reader: false, instance_writer: false
      self._reflections = {}

      { embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne }.each do |(name, reflection_class)|
        define_singleton_method name do |*args|
          reflection = reflection_class.new *args
          reflection.define_methods self
          self._reflections = _reflections.merge(reflection.name => reflection)
        end
      end
    end

    module ClassMethods
      def reflect_on_association name
        _reflections[name.to_sym]
      end

      def reflections
        _reflections
      end
    end

    def association name
      @_associations ||= {}
      @_associations[name.to_sym] ||= self.class.reflect_on_association(name).builder(self)
    end

    def == other
      super(other) && self.class.reflections.keys.all? do |association|
        send(association) == other.send(association)
      end
    end
  end
end
