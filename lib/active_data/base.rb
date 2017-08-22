require 'active_data/model'
require 'active_data/model/primary'
require 'active_data/model/lifecycle'
require 'active_data/model/associations'

module ActiveData
  class Base
    include ActiveData::Model
    include ActiveData::Model::Primary
    include ActiveData::Model::Lifecycle
    include ActiveData::Model::Associations
  end
end
