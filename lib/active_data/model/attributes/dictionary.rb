module ActiveData
  module Model
    module Attributes
      class Dictionary < Attribute
        delegate :keys, to: :reflection

        def read
          @value ||= begin
            hash = read_before_type_cast
            hash = hash.stringify_keys.slice(*keys) if keys.present?

            normalize(Hash[hash.map do |key, value|
              [key, enumerize(typecast(value))]
            end].with_indifferent_access).with_indifferent_access
          end
        end

        def read_before_type_cast
          @value_before_type_cast ||= Hash[(@value_cache.presence || {}).map do |key, value|
            [key, defaultize(value)]
          end].with_indifferent_access
        end
      end
    end
  end
end
