module ActiveData
  module Model
    module Attributes
      module Reflections
        class Dictionary < Attribute
          def keys
            @keys ||= Array.wrap(options[:keys]).map(&:to_s)
          end
        end
      end
    end
  end
end
