require 'bundler'
require 'pry'
Bundler.require

require 'rspec/its'
require 'active_record'
require 'rack/test'
require 'action_controller/metal/strong_parameters'
require 'database_cleaner'

require 'support/model_helpers'
require 'support/muffle_helper'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new('/dev/null')

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :email, :string
    t.column :projects, :text
    t.column :profile, :text
  end

  create_table :authors do |t|
    t.column :name, :string
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = :random
  config.run_all_when_everything_filtered = true
  config.filter_run focus: true

  config.include ModelHelpers
  config.include MuffleHelpers

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
