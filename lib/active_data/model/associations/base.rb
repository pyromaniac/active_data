module ActiveData
  module Model
    module Associations
      class Base
        attr_accessor :reflection, :owner, :target

        def initialize owner, reflection
          @owner, @reflection = owner, reflection
          reset
        end

        def reset
          @loaded = false
          @target = nil
        end

        def loaded?
          !!@loaded
        end

        def loaded!
          @loaded = true
        end

        def reload
          reset
          load_target
        end

        def transaction &block
          data = Marshal.load(Marshal.dump(read_source))
          block.call
        rescue StandardError => e
          write_source data
          reload
          raise e
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
