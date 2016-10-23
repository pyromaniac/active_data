module ActiveData
  module Model
    module Associations
      class ReferencesMany < ReferenceAssociation
        def apply_changes
          present_keys = target.reject(&:marked_for_destruction?).map do |obj|
            reflection.persistence_adapter.identify(obj)
          end
          write_source(present_keys)
          true
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

        def read_source
          attribute.read_before_type_cast
        end

        def write_source(value)
          attribute.write_value value
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
              apply_changes!
            end
          end
          target
        end

        def attribute
          @attribute ||= owner.attribute(reflection.reference_key)
        end
      end
    end
  end
end
