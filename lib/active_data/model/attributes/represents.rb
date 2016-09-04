module ActiveData
  module Model
    module Attributes
      class Represents < Attribute
        delegate :reader, :reader_before_type_cast, :writer, to: :reflection

        def write(value)
          return if readonly?
          pollute do
            reset
            reference.send(writer, value)
          end
        end

        def reset
          super
          remove_variable(:cached_value, :cached_value_before_type_cast)
        end

        def read
          reset if cached_value != read_value
          variable_cache(:value) do
            normalize(enumerize(defaultize(cached_value, read_before_type_cast)))
          end
        end

        def read_before_type_cast
          reset if cached_value_before_type_cast != read_value_before_type_cast
          variable_cache(:value_before_type_cast) do
            defaultize(cached_value_before_type_cast)
          end
        end

      private

        def reference
          owner.send(reflection.reference)
        end

        def read_value
          ref = reference
          ref.public_send(reader) if ref
        end

        def cached_value
          variable_cache(:cached_value) { read_value }
        end

        def read_value_before_type_cast
          ref = reference
          return unless ref
          if ref.respond_to?(reader_before_type_cast)
            ref.public_send(reader_before_type_cast)
          else
            ref.public_send(reader)
          end
        end

        def cached_value_before_type_cast
          variable_cache(:cached_value_before_type_cast) { read_value_before_type_cast }
        end
      end
    end
  end
end
