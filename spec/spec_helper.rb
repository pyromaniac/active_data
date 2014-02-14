require 'bundler'
Bundler.require

require 'coveralls'
Coveralls.wear!

require 'active_record'
require 'database_cleaner'

require 'support/model_helpers'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new('/dev/null')

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :name, :string
    t.column :abilities, :text
    t.column :tracking, :text
  end
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.include ModelHelpers

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
