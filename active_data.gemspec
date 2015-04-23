# -*- encoding: utf-8 -*-
require File.expand_path('../lib/active_data/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['pyromaniac']
  gem.email         = ['kinwizard@gmail.com']
  gem.description   = %q{Making object from any hash or hash array}
  gem.summary       = %q{Working with hashes in AR style}
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'active_data'
  gem.require_paths = ['lib']
  gem.version       = ActiveData::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubysl', '~> 2.0' if RUBY_ENGINE == 'rbx'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'sqlite3', '1.3.8'
  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'activerecord', '>= 4.1'
  gem.add_development_dependency 'uuidtools'
  gem.add_runtime_dependency 'activesupport', '>= 4.1'
  gem.add_runtime_dependency 'activemodel', '>= 4.1'
  gem.add_runtime_dependency 'tzinfo'
end
