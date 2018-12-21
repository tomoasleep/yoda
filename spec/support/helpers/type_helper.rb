module TypeHelper
  def instance_type(value)
    Yoda::Model::TypeExpressions::InstanceType.new(value)
  end

  def value_type(value)
    Yoda::Model::TypeExpressions::ValueType.new(value)
  end

  def module_type(value)
    Yoda::Model::TypeExpressions::ModuleType.new(value)
  end

  def duck_type(method_name)
    Yoda::Model::TypeExpressions::DuckType.new(method_name)
  end

  def union_type(*types)
    Yoda::Model::TypeExpressions::UnionType.new(types)
  end

  def unknown_type
    Yoda::Model::TypeExpressions::UnknownType.new
  end

  def any_type
    Yoda::Model::TypeExpressions::AnyType.new
  end

  def self_type
    Yoda::Model::TypeExpressions::SelfType.new
  end

  def generic_type(name, *type_arguments)
    Yoda::Model::TypeExpressions::GenericType.new(name, type_arguments)
  end

  def sequence_type(name, *types)
    Yoda::Model::TypeExpressions::SequenceType.new(name, types)
  end
end
