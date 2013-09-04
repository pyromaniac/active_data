require 'active_support/concern'
require 'active_support/core_ext'
require 'active_model'
require 'active_data/version'
require 'active_data/config'
require 'active_data/model'
require 'active_data/validations'

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

  singleton_class.delegate :include_root_in_json, :include_root_in_json=, to: :config
end
