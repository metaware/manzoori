# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pravangi/version'

Gem::Specification.new do |spec|
  spec.name          = "pravangi"
  spec.version       = Pravangi::VERSION
  spec.authors       = ["Jasdeep Singh"]
  spec.email         = ["narang.jasdeep@gmail.com"]
  spec.description   = %q{ਪ੍ਰਵਾਨਗੀ (pravangi) : Approval}
  spec.summary       = %q{ਪ੍ਰਵਾਨਗੀ (pravangi) : Approval}
  spec.homepage      = "http://metawarelabs.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
