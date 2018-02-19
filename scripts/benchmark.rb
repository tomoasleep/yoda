require 'yoda'
require 'benchmark'

Benchmark.bm do |b|
  b.report { Yoda::Runner::Setup.run(File.expand_path('../spec/support/fixtures', __dir__)) }
end
