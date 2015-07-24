module ActiveData
  module Model
    module Attributes
      class Dictionary < Base
        delegate :keys, to: :reflection

        def read_value hash
          hash = hash.presence || {}
          hash = hash.stringify_keys.slice(*keys) if keys.present?

          normalize(Hash[hash.map do |key, value|
            [key, enumerize(typecast(defaultize(value)))]
          end].with_indifferent_access).with_indifferent_access
        end

        def read_value_before_type_cast hash
          hash = hash.presence || {}

          Hash[hash.map do |key, value|
            [key, defaultize(value)]
          end].with_indifferent_access
        end
      end
    end
  end
end
