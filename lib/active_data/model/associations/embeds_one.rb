module ActiveData
  module Model
    module Associations
      class EmbedsOne < Base
        def build attributes = {}
          self.target = reflection.klass.new(attributes)
        end

        def create attributes = {}
          build(attributes).tap(&:save)
        end

        def create! attributes = {}
          build(attributes).tap(&:save!)
        end

        def apply_changes
          if target
            target.marked_for_destruction? || target.destroyed? ? clear : target.save
          else
            true
          end
        end

        def target= object
          setup_performers! object if object
          loaded!
          @target = object
        end

        def load_target
          source = read_source
          source ? reflection.klass.instantiate(source) : default
        end

        def default
          unless evar_loaded?
            default = reflection.default(owner)
            if default
              object = if default.is_a?(reflection.klass)
                default
              else
                reflection.klass.new.tap do |object|
                  object.assign_attributes(default, false)
                end
              end
              object.send(:clear_changes_information) if reflection.klass.dirty?
              object
            end
          end
        end

        def clear
          target.try(:destroy)
          reload.nil?
        end

        def reader force_reload = false
          reload if force_reload
          target
        end

        def replace object
          if object
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            transaction do
              clear
              self.target = object
              apply_changes! if owner.persisted?
            end
          else
            clear
          end

          target
        end
        alias_method :writer, :replace

      private

        def setup_performers! object
          association = self

          object.define_save do
            association.send(:write_source, attributes)
          end

          object.define_destroy do
            association.send(:write_source, nil)
            true
          end
        end
      end
    end
  end
end
