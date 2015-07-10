require 'active_data/model/associations/collection_proxy'

module ActiveData
  module Model
    module Associations
      class EmbeddedCollectionProxy < CollectionProxy
        delegate :build, :create, :create!, to: :@association
        alias_method :new, :build
      end
    end
  end
end
