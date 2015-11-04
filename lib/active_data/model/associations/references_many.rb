module ActiveData
  module Model
    module Associations
      class ReferencesMany < Base
        def apply_changes
          present_keys = target.reject { |t| t.marked_for_destruction? }.map(&reflection.primary_key)
          write_source(present_keys)
          true
        end

        def target= object
          loaded!
          @target = object.to_a
        end

        def load_target
          source = read_source
          source.present? ? scope(source).to_a : default
        end

        def default
          unless evar_loaded?
            default = Array.wrap(reflection.default(owner))
            if default.all? { |object| object.is_a?(reflection.klass) }
              default
            else
              scope(default).to_a
            end if default.present?
          end || []
        end

        def reader force_reload = false
          reload if force_reload || source_changed?
          @proxy ||= Collection::Referenced.new self
        end

        def replace objects
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
          write_source([])
          reload.empty?
        end

        def scope source = read_source
          reflection.scope.where(reflection.primary_key => source)
        end

      private

        def append objects
          objects.each do |object|
            next if target.include?(object)
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            target[target.size] = object
            apply_changes!
          end
          target
        end

        def identifiers
          target.map(&reflection.primary_key)
        end

        def source_changed?
          read_source != identifiers
        end
      end
    end
  end
end
