module ActiveData
  module Model
    module Associations
      class Base
        attr_accessor :reflection, :owner

        def initialize owner, reflection
          @owner, @reflection = owner, reflection
        end
      end
    end
  end
end
