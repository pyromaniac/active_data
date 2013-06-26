# -*- encoding: utf-8 -*-
require File.expand_path('../lib/active_data/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["pyromaniac"]
  gem.email         = ["kinwizard@gmail.com"]
  gem.description   = %q{Making object from any hash or hash array}
  gem.summary       = %q{Working with hashes in AR style}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "active_data"
  gem.require_paths = ["lib"]
  gem.version       = ActiveData::VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_runtime_dependency "activesupport"
  gem.add_runtime_dependency "activemodel"
end
