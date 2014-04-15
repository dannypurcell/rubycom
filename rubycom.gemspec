require "#{File.dirname(__FILE__)}/lib/rubycom/version.rb"

Gem::Specification.new do |spec|
  spec.name          = 'rubycom'
  spec.version       = Rubycom::VERSION
  spec.authors       = ['Danny Purcell']
  spec.email         = %w(d.purcell.jr+rubycom@gmail.com)
  spec.description   = %q{Enables command-line access for methods in an including module. Reads method documentation for command line help output. Parses command line options and flags. Turn your library into a command-line app by simply including Rubycom.}
  spec.summary       = %q{Turn your library into a command-line app by simply including Rubycom.}
  spec.homepage      = 'http://dannypurcell.github.io/rubycom'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'rake'
  spec.add_dependency 'yard'
  spec.add_dependency 'method_source'
  spec.add_dependency 'parslet'
end
