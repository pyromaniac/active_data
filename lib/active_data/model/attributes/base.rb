module ActiveData
  module Model
    module Attributes
      class Base
        attr_reader :owner, :reflection
        delegate :type, :typecaster, :defaultizer, :enumerizer, :normalizers, to: :reflection

        def initialize owner, reflection
          @owner, @reflection = owner, reflection
        end

        def read
          @raw_value
        end

        def read_before_type_cast
          @raw_value
        end

        def write value
          @raw_value = value
        end

        def value_present?
          !read.nil? && !(read.respond_to?(:empty?) && read.empty?)
        end

      private

        def evaluate *args, &block
          if block.arity >= 0 && block.arity <= args.length
            owner.instance_exec(*args.first(block.arity), &block)
          else
            args = block.arity < 0 ? args : args.first(block.arity)
            block.call(*args, owner)
          end
        end
      end
    end
  end
end
