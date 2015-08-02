module ActiveData
  module Model
    module Attributes
      class Represent < Attribute
        delegate :reader, :reader_before_type_cast, :writer, to: :reflection

        def write value
          @value = nil
          @value_before_type_cast = nil
          reference.send(writer, value)
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
          reference.public_send(reader)
        end

        def read_value_before_type_cast
          ref = reference
          ref.respond_to?(reader_before_type_cast) ?
            ref.public_send(reader_before_type_cast) :
            ref.public_send(reader)
        end
      end
    end
  end
end
