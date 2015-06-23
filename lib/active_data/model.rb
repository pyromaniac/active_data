require 'active_data/model/extensions'
require 'active_data/model/conventions'
require 'active_data/model/attributes'
require 'active_data/model/scopes'
require 'active_data/model/primary'
require 'active_data/model/lifecycle'
require 'active_data/model/persistence'
require 'active_data/model/callbacks'
require 'active_data/model/associations'

module ActiveData
  module Model
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      include ActiveModel::Conversion
      include ActiveModel::Validations
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON

      include Conventions
      include Attributes
    end
  end
end
