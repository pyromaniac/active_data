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
          target.map { |object| object.marked_for_destruction? ? object.destroy : object.save }.all?
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
          source = read_source
          source.present? ? reflection.klass.instantiate_collection(source) : default
        end

        def default
          unless evar_loaded?
            default = Array.wrap(reflection.default(owner))
            if default.all? { |object| object.is_a?(reflection.klass) }
              default
            else
              default.map { |attributes| reflection.klass.new(attributes) }
            end if default.present?
          end || []
        end

        def reset
          super
          @target = []
        end

        def clear
          transaction { target.all?(&:destroy!) } rescue ActiveData::ObjectNotDestroyed
          reload.empty?
        end

        def reader force_reload = false
          reload if force_reload
          @proxy ||= Collection::Embedded.new self
        end

        def writer objects
          replace objects
        end

        def replace objects
          transaction do
            clear
            append(objects) or raise ActiveData::AssociationNotSaved
          end
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
          result && target
        end

        def push_object object
          setup_performers! object
          target[target.size] = object
        end

        def setup_performers! object
          association = self

          object.define_create do
            source = association.send(:read_source)
            index = association.target.select do |one|
              one.persisted? || one === self
            end.index { |one| one === self }

            source.insert(index, attributes)
            association.send(:write_source, source)
          end

          object.define_update do
            source = association.send(:read_source)
            index = association.target.select(&:persisted?).index { |one| one === self }

            source[index] = attributes
            association.send(:write_source, source)
          end

          object.define_destroy do
            source = association.send(:read_source)
            index = association.target.select(&:persisted?).index { |one| one === self }

            source.delete_at(index) if index
            association.send(:write_source, source)
          end
        end
      end
    end
  end
end
