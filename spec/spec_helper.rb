require "bundler/setup"
require 'rspec-benchmark'
require "yoda"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include RSpec::Benchmark::Matchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

YARD::Logger.instance(File.open(File::Constants::NULL, 'w'))

module TypeHelper
  def instance_type(value)
    Yoda::Store::Types::InstanceType.new(value)
  end

  def value_type(value)
    Yoda::Store::Types::ValueType.new(value)
  end

  def module_type(value)
    Yoda::Store::Types::ModuleType.new(value)
  end

  def duck_type(method_name)
    Yoda::Store::Types::DuckType.new(method_name)
  end

  def union_type(*types)
    Yoda::Store::Types::UnionType.new(types)
  end

  def generic_type(name, *type_arguments)
    Yoda::Store::Types::GenericType.new(name, type_arguments)
  end

  def sequence_type(name, *types)
    Yoda::Store::Types::SequenceType.new(name, types)
  end
end
