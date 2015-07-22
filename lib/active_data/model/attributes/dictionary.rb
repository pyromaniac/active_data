module ActiveData
  module Model
    module Attributes
      class Dictionary < Base
        def keys
          @keys = Array.wrap(options[:keys]).map(&:to_s)
        end

        def read_value hash, context
          hash = hash.presence || {}
          hash = hash.stringify_keys.slice(*keys) if keys.present?

          normalize(Hash[hash.map do |key, value|
            [key, enumerize(type_cast(defaultize(value, context), context), context)]
          end].with_indifferent_access, context).with_indifferent_access
        end

        def read_value_before_type_cast hash, context
          hash = hash.presence || {}

          Hash[hash.map do |key, value|
            [key, defaultize(value, context)]
          end].with_indifferent_access
        end
      end
    end
  end
end
