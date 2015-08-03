module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        def save
          return false if target && !target.persisted?
          if target.present? && !target.marked_for_destruction?
            write_source identifier
          else
            write_source nil
          end
          true
        end

        def save!
          save or raise AssociationObjectNotPersisted
        end

        def target= object
          loaded!
          @target = object
        end

        def load_target
          source = read_source
          source ? scope(source).first : default
        end

        def default
          unless evar_loaded?
            default = reflection.default(owner)
            if default.is_a?(reflection.klass)
              default
            else
              scope(default).first
            end if default
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
            save!
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
