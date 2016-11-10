module ActiveData
  module Model
    module Attributes
      class Attribute < Base
        delegate :defaultizer, :enumerizer, :normalizers, to: :reflection

        def write(value)
          return if readonly?
          pollute do
            write_value value
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

        def defaultize(value, default_value = nil)
          !defaultizer.nil? && value.nil? ? default_value || default : value
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

        def enumerize(value)
          set = enum if enumerizer
          value if !set || (set.none? || set.include?(value))
        end

        def normalize(value)
          if normalizers.none?
            value
          else
            normalizers.inject(value) do |val, normalizer|
              case normalizer
              when Proc
                evaluate(val, &normalizer)
              when Hash
                normalizer.inject(val) do |v, (name, options)|
                  ActiveData.normalizer(name).call(v, options, self)
                end
              else
                ActiveData.normalizer(normalizer).call(val, {}, self)
              end
            end
          end
        end
      end
    end
  end
end
