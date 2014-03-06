module ActiveData
  module Model
    module Associations
      class EmbedsMany < Base
        def build attributes = {}
          push_object(reflection.klass.new(attributes))
        end

        def create attributes = {}
          build(attributes).tap(&:save)
        end

        def create! attributes = {}
          build(attributes).tap(&:save!)
        end

        def save
          load_target.map { |object| object.marked_for_destruction? ? object.destroy : object.save }.all?
        end

        def save!
          save or raise ActiveData::AssociationNotSaved
        end

        def target= objects
          objects.each { |object| setup_performers! object }
          loaded!
          @target = objects
        end

        def load_target
          return target if loaded?
          data = read_source
          self.target = data ? reflection.klass.instantiate_collection(data) : []
        end

        def reset
          super
          @target = []
        end

        def clear
          transaction { load_target.all?(&:destroy!) } rescue ActiveData::ObjectNotDestroyed
          reload.empty?
        end

        def reader force_reload = false
          reload if force_reload
          @proxy ||= CollectionProxy.new self
        end

        def replace objects
          transaction do
            clear
            append(objects) or raise ActiveData::AssociationNotSaved
          end
        end

        def writer objects
          replace objects
        end

        def concat *objects
          append objects.flatten
        end

      private

        def read_source
          super || []
        end

        def append objects
          objects.each do |object|
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object && object.is_a?(reflection.klass)
            push_object object
          end
          result = owner.persisted? ? save : true
          result && load_target
        end

        def push_object object
          setup_performers! object
          load_target[load_target.size] = object
        end

        def setup_performers! object
          association = self

          object.define_create do
            data = association.send(:read_source)
            index = association.load_target.select do |object|
              object.persisted? || object === self
            end.index { |object| object === self }

            data.insert(index, attributes)
            association.send(:write_source, data)
          end

          object.define_update do
            data = association.send(:read_source)
            index = association.load_target.select(&:persisted?).index { |object| object === self }

            data[index] = attributes
            association.send(:write_source, data)
          end

          object.define_destroy do
            data = association.send(:read_source)
            index = association.load_target.select(&:persisted?).index { |object| object === self }

            data.delete_at(index) if index
            association.send(:write_source, data)
          end
        end
      end
    end
  end
end
