module ActiveData
  module Model
    module Attributes
      class Base
        attr_reader :owner, :reflection
        delegate :name, :type, to: :reflection

        def initialize owner, reflection
          @owner, @reflection = owner, reflection
        end

        def write value
          @raw_value = value
        end

        def read
          @raw_value
        end

        def read_before_type_cast
          @raw_value
        end

        def value_present?
          !read.nil? && !(read.respond_to?(:empty?) && read.empty?)
        end

        def inspect_attribute
          value = case type
          when Date, Time, DateTime
            %("#{read.to_s(:db)}")
          else
            read.inspect.truncate(50)
          end
          "#{name}: #{value}"
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
