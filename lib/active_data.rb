require 'active_support/concern'
require 'active_support/core_ext'
require 'active_support/dependencies'

ActiveSupport::Dependencies.autoload_paths += [File.dirname(__FILE__)]

require 'active_model'
require 'active_data/version'

module ActiveData
  class ActiveDataError < StandardError
  end

  class NotFound < ActiveDataError
  end

  class UnknownAttributeError < NoMethodError
  end

  class IncorrectEntity < ActiveDataError
    def initialize expected, got
      super "Expected `#{expected}`, but got `#{got}`"
    end
  end

  def self.config; Config.instance; end

  singleton_class.delegate :include_root_in_json, :include_root_in_json=, :i18n_scope, :i18n_scope=, to: :config
end
