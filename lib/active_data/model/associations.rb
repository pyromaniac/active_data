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
            if defined? before_save
              callback_name = "update_#{reflection.name}_association"
              before_save callback_name
              class_eval <<-METHOD
                def #{callback_name}
                  association(:#{reflection.name}).save!
                end
              METHOD
            end
          end
        end
      end

      module ClassMethods
        def reflect_on_association name
          reflections[name.to_sym]
        end

        def inspect
          attributes = _attributes.map do |name, attribute|
            data = if reflection = reflect_on_association(name)
              case reflection.macro
              when :embeds_one
                reflection.klass
              when :embeds_many
                "[#{reflection.klass}, ...]"
              end
            else
              attribute.type
            end
            "#{name}: #{data}"
          end.join(', ')

          "#{name}(#{attributes})"
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
