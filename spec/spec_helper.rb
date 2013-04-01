require 'bundler'
Bundler.require

# Just global Collection class to avoid class names collisions
module Collection
end

RSpec.configure do |config|
  config.mock_with :rspec
end
