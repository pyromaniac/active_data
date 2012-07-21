source 'https://rubygems.org'

# Specify your gem's dependencies in active_data.gemspec
gemspec

gem 'guard'
gem 'guard-rspec'

if RUBY_PLATFORM =~ /darwin/i
  gem 'rb-fsevent'
else
  gem 'rb-inotify'
  gem 'libnotify'
end
