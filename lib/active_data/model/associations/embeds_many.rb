module ActiveData
  module Model
    module Associations
      class EmbedsMany < EmbedsAny
        def build(attributes = {})
          push_object(build_object(attributes))
        end

        def create(attributes = {})
          build(attributes).tap(&:save)
        end

        def create!(attributes = {})
          build(attributes).tap(&:save!)
        end

        def destroyed
          @destroyed ||= []
        end

        def apply_changes
          result = target.map do |object|
            object.destroyed? || object.marked_for_destruction? ? object.destroy : object.save
          end.all?
          @destroyed = target.select(&:destroyed?)
          target.delete_if(&:destroyed?)
          result
        end

        def target=(objects)
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
            if default.present?
              collection = if default.all? { |object| object.is_a?(reflection.klass) }
                default
              else
                default.map do |attributes|
                  reflection.klass.with_sanitize(false) do
                    build_object(attributes)
                  end
                end
              end
              collection.map { |object| object.send(:clear_changes_information) } if reflection.klass.dirty?
              collection
            end
          end || []
        end

        def reset
          super
          @target = []
        end

        def clear
          begin
            transaction { target.all?(&:destroy!) }
          rescue ActiveData::ObjectNotDestroyed
            nil
          end
          reload.empty?
        end

        def reader(force_reload = false)
          reload if force_reload
          @proxy ||= Collection::Embedded.new self
        end

        def replace(objects)
          transaction do
            clear
            append(objects) or raise ActiveData::AssociationChangesNotApplied
          end
        end
        alias_method :writer, :replace

        def concat(*objects)
          append objects.flatten
        end

      private

        def read_source
          super || []
        end

        def append(objects)
          objects.each do |object|
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object && object.is_a?(reflection.klass)
            push_object object
          end
          result = owner.persisted? ? apply_changes : true
          result && target
        end

        def push_object(object)
          setup_performers! object
          target[target.size] = object
          object
        end

        def setup_performers!(object)
          embed_object(object)
          callback(:before_add, object)

          association = self

          object.define_create do
            source = association.send(:read_source)
            index = association.target
              .select { |one| one.persisted? || one.equal?(self) }
              .index { |one| one.equal?(self) }

            source.insert(index, attributes)
            association.send(:write_source, source)
          end

          object.define_update do
            source = association.send(:read_source)
            index = association.target.select(&:persisted?).index { |one| one.equal?(self) }

            source[index] = attributes
            association.send(:write_source, source)
          end

          object.define_destroy do
            source = association.send(:read_source)
            index = association.target.select(&:persisted?).index { |one| one.equal?(self) }

            source.delete_at(index) if index
            association.send(:write_source, source)
          end

          callback(:after_add, object)
        end
      end
    end
  end
end
