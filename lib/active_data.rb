require 'active_support/concern'
require 'active_support/core_ext'
require 'active_support/dependencies'

ActiveSupport::Dependencies.autoload_paths += [File.dirname(__FILE__)]

require 'active_model'
require 'active_data/version'
require 'active_data/config'
require 'active_data/model'
require 'active_data/model/extensions'

module ActiveData
  class ActiveDataError < StandardError
  end

  class NotFound < ActiveDataError
  end

  class UnknownAttributeError < NoMethodError
  end

  class NormalizerMissing < NoMethodError
    def initialize name
      super <<-EOS
Could not find normalizer `:#{name}`
You can define it with:

  ActiveData.normalizer(:#{name}) do |value, options|
    # do some staff with value and options
  end
      EOS
    end
  end

  class IncorrectEntity < ActiveDataError
    def initialize expected, got
      super "Expected `#{expected}`, but got `#{got}`"
    end
  end

  def self.config; ActiveData::Config.instance; end

  singleton_class.delegate :include_root_in_json, :include_root_in_json=,
    :i18n_scope, :i18n_scope=, :normalizer, to: :config
end
