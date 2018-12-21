require 'parslet'

module Yoda
  module Model
    module TypeExpressions
      require 'yoda/model/type_expressions/base'
      require 'yoda/model/type_expressions/any_type'
      require 'yoda/model/type_expressions/value_type'
      require 'yoda/model/type_expressions/instance_type'
      require 'yoda/model/type_expressions/function_type'
      require 'yoda/model/type_expressions/duck_type'
      require 'yoda/model/type_expressions/module_type'
      require 'yoda/model/type_expressions/sequence_type'
      require 'yoda/model/type_expressions/self_type'
      require 'yoda/model/type_expressions/generic_type'
      require 'yoda/model/type_expressions/union_type'
      require 'yoda/model/type_expressions/unknown_type'

      # @param string [String]
      # @return [TypeExpressions::Base]
      def self.parse(string)
        Parsing::Generator.new.apply(Parsing::Parser.new.parse(string))
      rescue Parslet::ParseFailed => failure
        TypeExpressions::UnknownType.new(string)
      end

      # @param strings [Array<String>]
      # @return [TypeExpressions::Base]
      def self.parse_type_strings(strings)
        TypeExpressions::UnionType.new(strings.map { |string| parse(string) })
      end

      module Parsing
        class Parser < Parslet::Parser
          rule(:method_name) { match('[a-z]') >> match('[a-zA-Z0-9_]').repeat }
          rule(:duck_type) { str('#') >> method_name.as(:method_name) }
          rule(:constant_name) { match('[A-Z]') >> match('[a-zA-Z0-9_]').repeat }
          rule(:constant_full_name) { str('::').maybe >> (constant_name >> (str('::') | str('.'))).repeat >> constant_name }
          rule(:value_name) { match('[a-z0-9]') >> match('[a-zA-Z0-9_]').repeat }

          rule(:space) { match('\s').repeat(1) }
          rule(:space?) { space.maybe }

          rule(:constant_type) { value_name.as(:value) | constant_full_name.as(:instance_type) }

          rule(:key_value_type) { constant_type.as(:base_type) >> str('{') >> space? >> type.as(:key_type) >> space? >> str('=>') >> space? >> type.as(:value_type) >> space? >> str('}') }
          rule(:sequence_type) { constant_type.as(:base_type) >> str('(') >> space? >> types.as(:value_types) >> space? >> str(')') }
          rule(:generic_type) { constant_type.as(:base_type) >> (str('<') >> space? >> type >> space? >> str('>')).repeat(1).as(:type_arguments) }

          rule(:shorthand_key_value) { str('{') >> space? >> type.as(:key_type) >> space? >> str('=>') >> space? >> type.as(:value_type) >> space? >> str('}') }
          rule(:shorthand_sequence) { str('(') >> space? >> types.as(:value_types) >> space? >> str(')') }
          rule(:shorthand_array) { str('<') >> space? >> type.as(:type_in_array) >> space? >> str('>') }

          rule(:union_type) { types.as(:types) }

          rule(:single_type) { duck_type | shorthand_key_value | shorthand_array | shorthand_sequence | generic_type | key_value_type | sequence_type | constant_type }
          rule(:types) { (single_type >> str(',') >> space?).repeat >> space? >> single_type }

          rule(:type) { union_type }
          rule(:base) { space? >> type >> space? }
          root :base
        end

        class Generator < Parslet::Transform
          rule(instance_type: simple(:instance_type)) { TypeExpressions::InstanceType.new(instance_type.to_s) }
          rule(value: simple(:value)) { TypeExpressions::ValueType.new(value.to_s) }
          rule(value: 'self') { TypeExpressions::SelfType.new }

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
end
