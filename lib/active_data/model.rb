require 'active_data/model/extensions'
require 'active_data/model/conventions'
require 'active_data/model/attributes'
require 'active_data/model/primary'
require 'active_data/model/collection'
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

      self.include_root_in_json = ActiveData.include_root_in_json
    end

    def initialize attributes = {}
      @attributes = self.class.initialize_attributes
      assign_attributes attributes
    end

    def == other
      other.instance_of?(self.class) && other.attributes == attributes
    end
  end
end
