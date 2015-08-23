module ActiveData
  module Model
    module Attributes
      class Represent < Attribute
        delegate :reader, :reader_before_type_cast, :writer, to: :reflection

        def write value
          return if readonly?
          @value = nil
          @value_before_type_cast = nil
          ref = reference
          if ref
            ref.send(writer, value)
          else
            @value_cache = value
          end
        end

        def read
          @value ||= normalize(enumerize(defaultize(read_value, read_before_type_cast)))
        end

        def read_before_type_cast
          @value_before_type_cast ||= defaultize(read_value_before_type_cast)
        end

        def flush!
          if value_cache? && reference
            value_cache = @value_cache
            flush_value_cache
            write(value_cache)
          end
        end

      private

        def value_cache?
          instance_variable_defined?(:@value_cache)
        end

        def flush_value_cache
          remove_instance_variable(:@value_cache)
        end

        def reference
          owner.send(reflection.reference)
        end

        def read_value
          ref = reference
          if ref
            ref.public_send(reader)
          else
            @value_cache
          end
        end

        def read_value_before_type_cast
          ref = reference
          if ref
            ref.respond_to?(reader_before_type_cast) ?
              ref.public_send(reader_before_type_cast) :
              ref.public_send(reader)
          else
            @value_cache
          end
        end
      end
    end
  end
end
