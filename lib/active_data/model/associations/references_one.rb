module ActiveData
  module Model
    module Associations
      class ReferencesOne < ReferencesAny
        def build(attributes = {})
          replace(build_object(attributes))
        end

        def create(attributes = {})
          persist_object(build(attributes))
          target
        end

        def create!(attributes = {})
          persist_object(build(attributes), raise_error: true)
          target
        end

        def apply_changes
          if target
            if target.marked_for_destruction? && reflection.autosave?
              target.destroy
            elsif target.new_record? || (reflection.autosave? && target.changed?)
              persist_object(target)
            else
              true
            end
          else
            true
          end
        end

        def target=(object)
          loaded!
          @target = object
        end

        def load_target
          source = read_source
          source ? reflection.persistence_adapter.find_one(owner, source) : default
        end

        def default
          return if evar_loaded?

          default = reflection.default(owner)

          return unless default

          case default
          when reflection.persistence_adapter.data_type
            default
          when Hash
            build_object(default)
          else
            reflection.persistence_adapter.find_one(owner, default)
          end
        end

        def reader(force_reload = false)
          reset if force_reload
          target
        end

        def replace(object)
          raise_type_mismatch(object) unless object.nil? || matches_type?(object)

          transaction do
            attribute.pollute do
              self.target = object
              write_source identify
            end
          end

          target
        end
        alias_method :writer, :replace

        def identify
          reflection.persistence_adapter.identify(target)
        end
      end
    end
  end
end
