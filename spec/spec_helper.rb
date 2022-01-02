require "bundler/setup"
require 'rspec-benchmark'
require 'simplecov'
SimpleCov.start

require "yoda"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.filter_run_excluding heavy: true

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include RSpec::Benchmark::Matchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) do
    Yoda::Instrument.clean
  end
end

YARD::Logger.instance(File.open(File::Constants::NULL, 'w'))
require_relative './support/helpers'
