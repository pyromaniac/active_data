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

        def save
          target ? (target.marked_for_destruction? ? target.destroy : target.save) : true
        end

        def save!
          save or raise ActiveData::AssociationNotSaved
        end

        def target= object
          setup_performers! object if object
          loaded!
          @target = object
        end

        def target
          return @target if loaded?
          data = read_source
          self.target = data && reflection.klass.instantiate(data)
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
              save! if owner.persisted?
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
