%w[4.0 4.1 4.2 5.0 5.1 5.2].each do |version|
  appraise "rails.#{version}" do
    gem 'activesupport', "~> #{version}.0"
    gem 'activemodel', "~> #{version}.0"
    gem 'activerecord', "~> #{version}.0"
  end
end
