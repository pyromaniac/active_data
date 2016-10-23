module ActiveData
  module Model
    module Associations
      class ReferencesOne < ReferenceAssociation
        def build(attributes = {})
          self.target = build_object(attributes)
        end

        def create(attributes = {})
          build(attributes).tap(&:save)
        end

        def create!(attributes = {})
          build(attributes).tap(&:save!)
        end

        def apply_changes
          if target
            if target.marked_for_destruction? && reflection.autosave?
              target.destroy
            elsif target.new_record? || (reflection.autosave? && target.changed?)
              target.save
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

        def read_source
          attribute.read_before_type_cast
        end

        def write_source(value)
          attribute.write_value value
        end

        def reader(force_reload = false)
          reset if force_reload
          target
        end

        def replace(object)
          unless object.nil? || object.is_a?(reflection.persistence_adapter.data_type)
            raise AssociationTypeMismatch.new(reflection.persistence_adapter.data_type, object.class)
          end

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

      private

        def attribute
          @attribute ||= owner.attribute(reflection.reference_key)
        end
      end
    end
  end
end
