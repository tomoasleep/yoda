require "bundler/setup"
require "yoda"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module TypeHelper
  def instance_type(value)
    Yoda::Store::Types::InstanceType.new(value)
  end

  def constant_type(value)
    Yoda::Store::Types::ConstantType.new(value)
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

  def key_value_type(name, key_type, value_type)
    Yoda::Store::Types::KeyValueType.new(name, key_type, value_type)
  end

  def sequence_type(name, *types)
    Yoda::Store::Types::SequenceType.new(name, types)
  end
end
