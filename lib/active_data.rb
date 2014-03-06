require 'active_support/concern'
require 'active_support/core_ext'
require 'active_support/dependencies'
require 'singleton'

ActiveSupport::Dependencies.autoload_paths += [File.dirname(__FILE__)]

require 'active_model'
require 'active_data/version'
require 'active_data/errors'
require 'active_data/config'
require 'active_data/model'
require 'active_data/model/extensions'

ActiveSupport.on_load :active_record do
  include ActiveData::ActiveRecord::Associations
  include ActiveData::ActiveRecord::NestedAttributes
end

module ActiveData
  def self.config
    ActiveData::Config.instance
  end

  singleton_class.delegate *ActiveData::Config.delegated, to: :config
end
