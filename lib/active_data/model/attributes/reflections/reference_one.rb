module ActiveData
  module Model
    module Attributes
      module Reflections
        class ReferenceOne < Base
          TYPES = {
            integer: Integer,
            float: Float,
            decimal: BigDecimal,
            datetime: Time,
            timestamp: Time,
            time: Time,
            date: Date,
            text: String,
            string: String,
            binary: String,
            boolean: Boolean
          }
          def self.build target, generated_methods, name, *args, &block
            options = args.extract_options!
            generate_methods name, generated_methods
            type_proc = -> {
              reflection = target.reflect_on_association(options[:association])
              column = reflection.klass.columns_hash[reflection.primary_key.to_s]
              TYPES[column.type]
            }
            new(name, options.reverse_merge(type: type_proc))
          end

          def self.generate_methods name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                attribute('#{name}').read
              end

              def #{name}= value
                attribute('#{name}').write(value)
              end

              def #{name}?
                attribute('#{name}').value_present?
              end

              def #{name}_before_type_cast
                attribute('#{name}').read_before_type_cast
              end
            RUBY
          end

          def association
            @association ||= options[:association].to_s
          end
        end
      end
    end
  end
end
