
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "yoda/version"

Gem::Specification.new do |spec|
  spec.name          = "yoda-language-server"
  spec.version       = Yoda::VERSION
  spec.authors       = ["Tomoya Chiba"]
  spec.email         = ["tomo.asleep@gmail.com"]

  spec.summary       = %q{Ruby completion engine}
  spec.description   = %q{Ruby completion engine inspired by jedi}
  spec.homepage      = "https://github.com/tomoasleep/yoda"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'yard'
  spec.add_dependency 'thor'
  spec.add_dependency 'parslet'
  spec.add_dependency 'parser'
  spec.add_dependency 'unparser'
  spec.add_dependency 'language_server-protocol'
  spec.add_dependency 'rbs', "~> 2.0"
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'concurrent-ruby', '~> 1.1.0'
  spec.add_dependency 'rubyzip', '>= 1.0.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-benchmark"
  spec.add_development_dependency "stackprof"
end
