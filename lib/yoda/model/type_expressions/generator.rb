require 'parslet'

module Yoda
  module Model
    module TypeExpressions
      class Generator < Parslet::Transform
        rule(instance_type: simple(:instance_type)) { TypeExpressions::InstanceType.new(instance_type.to_s) }
        rule(value: simple(:value)) { TypeExpressions::ValueType.new(value.to_s) }
        rule(value: 'self') { TypeExpressions::SelfType.new }
        rule(value: 'void') { TypeExpressions::VoidType.new }

        rule(base_type: simple(:base_type), key_type: simple(:key_type), value_type: simple(:value_type)) { TypeExpressions::GenericType.from_key_value(base_type, key_type, value_type) }
        rule(base_type: simple(:base_type), value_types: sequence(:value_types)) { TypeExpressions::SequenceType.new(base_type, value_types) }
        rule(base_type: simple(:base_type), value_types: simple(:value_type)) { TypeExpressions::SequenceType.new(base_type, [value_type]) }
        rule(base_type: simple(:base_type), type_arguments: sequence(:type_arguments)) { TypeExpressions::GenericType.new(base_type, type_arguments) }

        rule(method_name: simple(:method_name)) { TypeExpressions::DuckType.new(method_name) }
        rule(key_type: simple(:key_type), value_type: simple(:value_type)) { TypeExpressions::GenericType.from_key_value(TypeExpressions::InstanceType.new('::Hash'), key_type, value_type) }
        rule(value_types: sequence(:value_types)) { TypeExpressions::SequenceType.new(TypeExpressions::InstanceType.new('::Array'), value_types) }
        rule(value_types: simple(:value_type)) { TypeExpressions::SequenceType.new(TypeExpressions::InstanceType.new('::Array'), [value_type]) }
        rule(type_in_array: simple(:type)) { TypeExpressions::GenericType.new(TypeExpressions::InstanceType.new('::Array'), [type]) }

        rule(types: sequence(:types)) { TypeExpressions::UnionType.new(types) }
        rule(types: simple(:type)) { type }
      end
    end
  end
end
