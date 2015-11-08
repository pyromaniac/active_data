module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        def apply_changes
          if target.present? && !target.marked_for_destruction?
            write_source identifier
          else
            write_source nil
          end
          true
        end

        def target= object
          loaded!
          @target = object
        end

        def load_target
          source = read_source
          scope(source).first if source
        end

        def default
          unless evar_loaded?
            default = reflection.default(owner)
            if default && default.is_a?(reflection.klass)
              default.id
            else
              default
            end
          end
        end

        def reader force_reload = false
          reset if force_reload || source_changed?
          target
        end

        def replace object
          unless object.nil?
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
          end

          transaction do
            self.target = object
            apply_changes!
          end

          target
        end
        alias_method :writer, :replace

        def scope source = read_source
          reflection.scope.where(reflection.primary_key => source)
        end

      private

        def identifier
          target.try(reflection.primary_key)
        end

        def source_changed?
          read_source != identifier
        end
      end
    end
  end
end
