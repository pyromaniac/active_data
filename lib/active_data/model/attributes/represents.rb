module ActiveData
  module Model
    module Attributes
      class Represents < Attribute
        delegate :reader, :reader_before_type_cast, :writer, to: :reflection

        def write value
          return if readonly?
          pollute do
            reset
            reference.send(writer, value)
          end
        end

        def read
          @value ||= normalize(enumerize(defaultize(read_value, read_before_type_cast)))
        end

        def read_before_type_cast
          @value_before_type_cast ||= defaultize(read_value_before_type_cast)
        end

      private

        def reference
          owner.send(reflection.reference)
        end

        def read_value
          ref = reference
          ref.public_send(reader) if ref
        end

        def read_value_before_type_cast
          ref = reference
          if ref
            ref.respond_to?(reader_before_type_cast) ?
              ref.public_send(reader_before_type_cast) :
              ref.public_send(reader)
          end
        end
      end
    end
  end
end
