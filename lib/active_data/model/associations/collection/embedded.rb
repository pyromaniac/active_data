module ActiveData
  module Model
    module Associations
      module Collection
        class Embedded < Proxy
          delegate :build, :create, :create!, to: :@association
          alias_method :new, :build
        end
      end
    end
  end
end
