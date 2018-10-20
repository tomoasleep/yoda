require 'yoda'
require 'benchmark'

Benchmark.bm do |b|
  b.report { Yoda::Cli::Setup.run(dir: File.expand_path('../spec/support/fixtures', __dir__), force_build: true) }
end
