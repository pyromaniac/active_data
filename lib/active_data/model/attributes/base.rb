module ActiveData
  module Model
    module Attributes
      class Base
        attr_reader :name, :owner
        delegate :type, :readonly, to: :reflection

        def initialize name, owner
          @name, @owner = name, owner
        end

        def reflection
          @owner.class._attributes[name]
        end

        def write value
          return if readonly?
          @value_cache = value
          value
        end

        def read
          @value_cache
        end

        def read_before_type_cast
          @value_cache
        end

        def value_present?
          !read.nil? && !(read.respond_to?(:empty?) && read.empty?)
        end

        def readonly?
          !!(readonly.is_a?(Proc) ? evaluate(&readonly) : readonly)
        end

        def inspect_attribute
          value = case type
          when Date, Time, DateTime
            %("#{read.to_s(:db)}")
          else
            inspection = read.inspect
            inspection.size > 100 ? inspection.truncate(50) : inspection
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
