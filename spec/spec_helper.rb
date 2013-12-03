require 'bundler'
Bundler.require

require 'support/model_helpers'

RSpec.configure do |config|
  config.mock_with :rspec

  config.include ModelHelpers
end
