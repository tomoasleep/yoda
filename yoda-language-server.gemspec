
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

  spec.add_dependency 'yard', '~> 0.9.11'
  spec.add_dependency 'thor', '~> 0.20.0'
  spec.add_dependency 'parslet', '~> 1.8'
  spec.add_dependency 'parser', '~> 2.0'
  spec.add_dependency 'unparser', '~> 0.2.6'
  spec.add_dependency 'language_server-protocol', '~> 3.12.0.0'
  spec.add_dependency 'leveldb', '~> 0.1.9'
  spec.add_dependency 'lmdb', '~> 0.4.8'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'concurrent-ruby', '~> 1.0.0'
  spec.add_dependency 'rubyzip', '>= 1.0.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-benchmark", "~> 0.3"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "pry-rescue", "~> 1.4"
  spec.add_development_dependency "pry-stack_explorer", "~> 0.4"
  spec.add_development_dependency "stackprof"
end
