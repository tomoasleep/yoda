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

  config.before(:each) do
    Yoda::Logger.log_level = :error
  end

  config.after(:each) do
    Yoda::Instrument.clean
    Yoda::Store::Adapters.clean
  end

  config.around(:each) do |example|
    if example.metadata[:fork]
      begin
        current_setting = Yoda.inline_process?
        Yoda.inline_process = false
        example.run
      ensure
        Yoda.inline_process = current_setting
      end
    else
      begin
        current_setting = Yoda.inline_process?
        Yoda.inline_process = true
        example.run
      ensure
        Yoda.inline_process = current_setting
      end
    end
  end
end

YARD::Logger.instance(File.open(File::Constants::NULL, 'w'))
require_relative './support/helpers'
