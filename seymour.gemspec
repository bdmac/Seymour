# -*- encoding: utf-8 -*-
require File.expand_path('../lib/seymour/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Brian McManus"]
  gem.email         = ["bdmac97@gmail.com"]
  gem.description   = %q{Activity Feed Support for Mongoid}
  gem.summary       = %q{Feed me Seymour!}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "seymour"
  gem.require_paths = ["lib"]
  gem.version       = Seymour::VERSION

  gem.add_development_dependency "rspec", "~> 2.8"
  gem.add_development_dependency "mongoid", "~> 2.4"
  gem.add_development_dependency "bson_ext", "~> 1.4"
  gem.add_development_dependency "rake"

  gem.add_dependency('mongoid')
end
