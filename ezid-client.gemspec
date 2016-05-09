# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "ezid-client"
  spec.version       = File.read(File.expand_path("../VERSION", __FILE__)).chomp
  spec.authors       = ["David Chandek-Stark"]
  spec.email         = ["dchandekstark@gmail.com"]
  spec.summary       = "Ruby client for EZID API Version 2"
  spec.description   = "Ruby client for EZID API Version 2 (http://ezid.cdlib.org/doc/apidoc.html)"
  spec.homepage      = "https://github.com/duke-libraries/ezid-client"
  spec.license       = "BSD-3-Clause"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.0"

  spec.add_dependency "hashie", "~> 3.4", ">= 3.4.3"
  spec.add_dependency "activemodel", "~> 4.0"
  spec.add_dependency "hydra-validations", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rspec-its", "~> 1.2"
end
