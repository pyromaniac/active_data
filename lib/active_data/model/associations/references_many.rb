module ActiveData
  module Model
    module Associations
      class ReferencesMany < ReferencesAny
        def build(attributes = {})
          append([build_object(attributes)]).last
        end

        def create(attributes = {})
          object = build(attributes)
          persist_object(object)
          object
        end

        def create!(attributes = {})
          object = build(attributes)
          persist_object(object, raise_error: true)
          object
        end

        def destroyed
          @destroyed ||= []
        end

        def apply_changes
          @destroyed = []

          result = target.all? do |object|
            if object
              if object.marked_for_destruction?
                @destroyed.push(object)
                if reflection.autosave?
                  object.destroy
                else
                  true
                end
              elsif object.destroyed?
                @destroyed.push(object)
                true
              elsif object.new_record? || (reflection.autosave? && object.changed?)
                persist_object(object)
              else
                true
              end
            else
              true
            end
          end

          @target -= @destroyed
          result
        end

        def target=(object)
          loaded!
          @target = object.to_a
        end

        def load_target
          source = read_source
          source.present? ? reflection.persistence_adapter.find_all(owner, source) : default
        end

        def default
          return [] if evar_loaded?

          default = Array.wrap(reflection.default(owner))

          return [] unless default

          if default.all? { |object| object.is_a?(reflection.persistence_adapter.data_type) }
            default
          elsif default.all? { |object| object.is_a?(Hash) }
            default.map { |attributes| build_object(attributes) }
          else
            reflection.persistence_adapter.find_all(owner, default)
          end || []
        end

        def reader(force_reload = false)
          reload if force_reload
          @proxy ||= reflection.persistence_adapter.referenced_proxy(self)
        end

        def replace(objects)
          loaded!
          transaction do
            clear
            append objects
          end
        end
        alias_method :writer, :replace

        def concat(*objects)
          append objects.flatten
          reader
        end

        def clear
          attribute.pollute do
            write_source([])
          end
          reload.empty?
        end

        def identify
          target.map { |obj| reflection.persistence_adapter.identify(obj) }
        end

      private

        def append(objects)
          attribute.pollute do
            objects.each do |object|
              next if target.include?(object)
              unless object.is_a?(reflection.persistence_adapter.data_type)
                raise AssociationTypeMismatch.new(reflection.persistence_adapter.data_type, object.class)
              end
              target.push(object)
              write_source(identify)
            end
          end
          target
        end
      end
    end
  end
end
