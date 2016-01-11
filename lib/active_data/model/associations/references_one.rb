module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        def apply_changes
          if target && !target.marked_for_destruction?
            write_source identify
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
          source ? scope(source).first : default
        end

        def default
          unless evar_loaded?
            default = reflection.default(owner)
            case default
            when reflection.klass
              default
            when Hash
              reflection.klass.new(default)
            else
              scope(default).first
            end if default
          end
        end

        def read_source
          attribute.read_before_type_cast
        end

        def write_source value
          attribute.write_value value
        end

        def reader force_reload = false
          reset if force_reload
          target
        end

        def replace object
          unless object.nil? || object.is_a?(reflection.klass)
            raise AssociationTypeMismatch.new(reflection.klass, object.class)
          end

          transaction do
            attribute.pollute do
              self.target = object
              apply_changes!
            end
          end

          target
        end
        alias_method :writer, :replace

        def scope source = read_source
          reflection.scope.where(reflection.primary_key => source)
        end

        def identify
          target.try(reflection.primary_key)
        end

      private

        def attribute
          @attribute ||= owner.attribute(reflection.reference_key)
        end
      end
    end
  end
end
