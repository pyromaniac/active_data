%w[4.2 5.0 5.1 5.2 6.0 6.1 7.0].each do |version|
  appraise "rails.#{version}" do
    gem 'activesupport', "~> #{version}.0"
    gem 'activemodel', "~> #{version}.0"
    gem 'activerecord', "~> #{version}.0"
    gem 'sqlite3', '~> 1.3.6' if version < '6.0'
  end
end
