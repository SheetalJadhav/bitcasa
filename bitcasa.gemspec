# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitcasa/version'

Gem::Specification.new do |spec|
  spec.name          = "bitcasa"
  spec.version       = Bitcasa::VERSION
  spec.authors       = ["Sheetal Jadhav"]
  spec.email         = ["sheetal.jadhav@izeltech.com"]
  spec.summary       = %q{Bitcasa}
  spec.description   = %q{Bitcasa}
  spec.homepage      = "https://github.com/SheetalJadhav/bitcasa.git"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', 'bin/*', 'test/**/*', 'extra/**/*','Rakefile', '.yardopts']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.has_rdoc      = false
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "yard"
  spec.add_development_dependency "rspec"
  spec.add_dependency "httpclient"
  spec.add_dependency "multi_json"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
end
