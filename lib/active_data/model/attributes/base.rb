module ActiveData
  module Model
    module Attributes
      class Base
        attr_reader :name, :owner
        delegate :type, :typecaster, :readonly, to: :reflection

        def initialize(name, owner)
          @name = name
          @owner = owner
          @origin = :default
        end

        def reflection
          @owner.class._attributes[name]
        end

        def write_value(value, origin: :user)
          reset
          @origin = origin
          @value_cache = value
        end

        def write(value)
          return if readonly?
          write_value value
        end

        def reset
          remove_variable(:value, :value_before_type_cast)
        end

        def read
          @value_cache
        end

        def read_before_type_cast
          @value_cache
        end

        def came_from_user?
          @origin == :user
        end

        def came_from_default?
          @origin == :default
        end

        def value_present?
          !read.nil? && !(read.respond_to?(:empty?) && read.empty?)
        end

        def query
          !(read.respond_to?(:zero?) ? read.zero? : read.blank?)
        end

        def typecast(value)
          if value.instance_of?(type)
            value
          else
            typecaster.call(value, self) unless value.nil?
          end
        end

        def readonly?
          !!(readonly.is_a?(Proc) ? evaluate(&readonly) : readonly)
        end

        def inspect_attribute
          value = case read
          when Date, Time, DateTime
            %("#{read.to_s(:db)}")
          else
            inspection = read.inspect
            inspection.size > 100 ? inspection.truncate(50) : inspection
          end
          "#{name}: #{value}"
        end

        def pollute
          pollute = owner.class.dirty? && !owner.send(:attribute_changed?, name)

          if pollute
            previous_value = owner.__send__(name)
            owner.send("#{name}_will_change!")

            result = yield

            owner.__send__(:clear_attribute_changes, [name]) if owner.__send__(name) == previous_value

            if previous_value != read || (
              read.respond_to?(:changed?) &&
              read.changed?
            )
              owner.send(:set_attribute_was, name, previous_value)
            end
            result
          else
            yield
          end
        end

      private

        def evaluate(*args, &block)
          if block.arity >= 0 && block.arity <= args.length
            owner.instance_exec(*args.first(block.arity), &block)
          else
            args = block.arity < 0 ? args : args.first(block.arity)
            yield(*args, owner)
          end
        end

        def remove_variable(*names)
          names.flatten.each do |name|
            name = :"@#{name}"
            remove_instance_variable(name) if instance_variable_defined?(name)
          end
        end

        def variable_cache(name)
          name = :"@#{name}"
          if instance_variable_defined?(name)
            instance_variable_get(name)
          else
            instance_variable_set(name, yield)
          end
        end
      end
    end
  end
end
