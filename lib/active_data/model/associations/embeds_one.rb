module ActiveData
  module Model
    module Associations
      class EmbedsOne < Base
        def build attributes = {}
          assign_object reflection.klass.new(attributes)
        end

        def create attributes = {}
          build(attributes).tap(&:save)
        end

        def create! attributes = {}
          build(attributes).tap(&:save!)
        end

        def save
          reader ? reader.save : true
        end

        def save!
          save or raise ActiveData::AssociationNotSaved
        end

        def reload
          reader(true)
        end

        def clear
          reader.try(:destroy)
          reload.nil?
        end

        def reader force_reload = false
          remove_instance_variable(:@target) if force_reload && instance_variable_defined?(:@target)
          instance_variable_defined?(:@target) ? @target : load_target!
        end

        def writer value
          if value
            transaction do
              assign_object value
              save! if owner.persisted?
            end
            value
          else
            write_source nil
            @target = nil
          end
        end

      private

        def assign_object object
          raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
          setup_performers! object
          @target = object
        end

        def load_target!
          data = read_source
          assign_object reflection.klass.instantiate(data) if data
        end

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
