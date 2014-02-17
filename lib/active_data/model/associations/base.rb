module ActiveData
  module Model
    module Associations
      class Base
        attr_accessor :reflection, :owner

        def initialize owner, reflection
          @owner, @reflection = owner, reflection
        end

        def transaction &block
          data = Marshal.load(Marshal.dump(read_source))
          block.call
        rescue StandardError => e
          write_source data
          reload
          raise e
        end

        def reload
          raise NotImplementedError
        end

      private

        def read_source
          reflection.read_source owner
        end

        def write_source value
          reflection.write_source owner, value
        end
      end
    end
  end
end
