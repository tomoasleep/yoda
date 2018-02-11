module TypeHelper
  def instance_type(value)
    Yoda::Model::Types::InstanceType.new(value)
  end

  def value_type(value)
    Yoda::Model::Types::ValueType.new(value)
  end

  def module_type(value)
    Yoda::Model::Types::ModuleType.new(value)
  end

  def duck_type(method_name)
    Yoda::Model::Types::DuckType.new(method_name)
  end

  def union_type(*types)
    Yoda::Model::Types::UnionType.new(types)
  end

  def unknown_type
    Yoda::Model::Types::UnknownType.new
  end

  def any_type
    Yoda::Model::Types::AnyType.new
  end

  def generic_type(name, *type_arguments)
    Yoda::Model::Types::GenericType.new(name, type_arguments)
  end

  def sequence_type(name, *types)
    Yoda::Model::Types::SequenceType.new(name, types)
  end
end
