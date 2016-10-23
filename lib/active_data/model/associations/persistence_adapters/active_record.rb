require 'active_data/model/associations/persistence_adapters/active_record/referenced_proxy'

module ActiveData
  module Model
    module Associations
      module PersistenceAdapters
        class ActiveRecord < Base
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
          }.freeze

          alias_method :data_type, :data_source

          def build(attributes)
            data_source.new(attributes)
          end

          def persist(object, raise_error: false)
            raise_error ? object.save! : object.save
          end

          def scope(owner, source)
            scope = data_source.unscoped

            if scope_proc
              scope = if scope_proc.arity.zero?
                scope.instance_exec(&scope_proc)
              else
                scope.instance_exec(owner, &scope_proc)
              end
            end

            scope.where(primary_key => source)
          end

          def identify(object)
            object[primary_key] if object
          end

          def primary_key
            @primary_key ||= :id
          end

          def primary_key_type
            column = data_source.columns_hash[primary_key.to_s]
            TYPES[column.type]
          end

          def referenced_proxy(association)
            ReferencedProxy.new(association)
          end
        end
      end
    end
  end
end
