module ActiveData
  module Model
    module Attributes
      class Attribute < Base
        delegate :defaultizer, :typecaster, :enumerizer, :normalizers, to: :reflection

        def write value
          pollute do
            reset
            super
          end
        end

        def read
          variable_cache(:value) do
            normalize(enumerize(typecast(read_before_type_cast)))
          end
        end

        def read_before_type_cast
          variable_cache(:value_before_type_cast) do
            defaultize(@value_cache)
          end
        end

        def default
          defaultizer.is_a?(Proc) ? evaluate(&defaultizer) : defaultizer
        end

        def defaultize value, default_value = nil
          defaultizer && value.nil? ? default_value || default : value
        end

        def typecast value
          if value.instance_of?(type)
            value
          else
            typecaster.call(value, self) unless value.nil?
          end
        end

        def enum
          source = enumerizer.is_a?(Proc) ? evaluate(&enumerizer) : enumerizer

          case source
          when Range
            source.to_a
          when Set
            source
          else
            Array.wrap(source)
          end.to_set
        end

        def enumerize value
          set = enum if enumerizer
          value if !set || (set.none? || set.include?(value))
        end

        def normalize value
          if normalizers.none?
            value
          else
            normalizers.inject(value) do |value, normalizer|
              case normalizer
              when Proc
                evaluate(value, &normalizer)
              when Hash
                normalizer.inject(value) do |value, (name, options)|
                  ActiveData.normalizer(name).call(value, options, self)
                end
              else
                ActiveData.normalizer(normalizer).call(value, {}, self)
              end
            end
          end
        end

      private

        def pollute
          pollute = owner.class.dirty? && !owner.send(:attribute_changed?, name)

          if pollute
            previous_value = read
            result = yield
            owner.send(:set_attribute_was, name, previous_value) if previous_value != read
            result
          else
            yield
          end
        end
      end
    end
  end
end
