# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubycom/version'

Gem::Specification.new do |spec|
  spec.name          = "rubycom"
  spec.version       = Rubycom::VERSION
  spec.authors       = ["Danny Purcell"]
  spec.email         = ["dpurcelljr@gmail.com"]
  spec.description   = %q{Allows command-line access for all singleton methods in an including class. Reads Yard style documentation for command line help output. Uses Yaml for parsing options. Allows the user to make a command-line tool by simply including Rubycom at the bottom.}
  spec.summary       = %q{Converts singleton methods to command-line functions upon inclusion.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "rake"
  spec.add_dependency 'method_source'
end
