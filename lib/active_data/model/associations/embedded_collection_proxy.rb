require 'active_data/model/associations/collection_proxy'

module ActiveData
  module Model
    module Associations
      class EmbeddedCollectionProxy < CollectionProxy
        delegate :build, :create, :create!, to: :@association
      end
    end
  end
end
