require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext'
require 'singleton'

require 'active_model'
require 'active_data/version'
require 'active_data/errors'
require 'active_data/config'

module ActiveData
  def self.config
    ActiveData::Config.instance
  end

  singleton_class.delegate *ActiveData::Config.delegated, to: :config
end

require 'active_data/model'
require 'active_data/validations'

ActiveSupport.on_load :active_record do
  require 'active_data/active_record/associations'
  require 'active_data/active_record/nested_attributes'

  include ActiveData::ActiveRecord::Associations
  include ActiveData::ActiveRecord::NestedAttributes
end
