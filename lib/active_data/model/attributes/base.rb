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
          @value_cache = value
          flush_represents! unless value.nil?
          @value_cache
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

        def flush_represents!
          owner.flush!(reflection.options[:flush_represents_of]) if reflection.options[:flush_represents_of]
        end

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
