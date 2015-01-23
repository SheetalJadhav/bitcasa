# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'Bitcasa/version'

Gem::Specification.new do |spec|
  spec.name          = "Bitcasa"
  spec.version       = Bitcasa::VERSION
  spec.authors       = ["Sheetal Jadhav"]
  spec.email         = ["sheetal.jadhav@izeltech.com"]
  spec.summary       = %q{Bitcasa}
  spec.description   = %q{Bitcasa}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "httpclient"
  spec.add_development_dependency "multi_json"
  #spec.add_development_dependency "rspec-nc"
  #spec.add_development_dependency "guard"
  #spec.add_development_dependency "guard-rspec"
  #spec.add_development_dependency "pry"
  #spec.add_development_dependency "pry-remote"
  #spec.add_development_dependency "pry-nav"
  #spec.add_development_dependency "coveralls"
  #spec.add_development_dependency "rspec-kickstarter"
  #spec.add_development_dependency "factory_girl"
end
