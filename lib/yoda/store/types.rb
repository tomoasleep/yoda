require 'parslet'

module Yoda
  module Store
    module Types
      require 'yoda/store/types/base'
      require 'yoda/store/types/any_type'
      require 'yoda/store/types/value_type'
      require 'yoda/store/types/instance_type'
      require 'yoda/store/types/function_type'
      require 'yoda/store/types/duck_type'
      require 'yoda/store/types/module_type'
      require 'yoda/store/types/sequence_type'
      require 'yoda/store/types/generic_type'
      require 'yoda/store/types/union_type'
      require 'yoda/store/types/unknown_type'

      # @param string [String]
      # @return [Types::Base]
      def self.parse(string)
        Parsing::Generator.new.apply(Parsing::Parser.new.parse(string))
      rescue Parslet::ParseFailed => failure
        Types::UnknownType.new(string)
      end

      # @param strings [Array<String>]
      # @return [Types::Base]
      def self.parse_type_strings(strings)
        Types::UnionType.new(strings.map { |string| parse(string) })
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
          rule(instance_type: simple(:instance_type)) { Types::InstanceType.new(instance_type.to_s) }
          rule(value: simple(:value)) { Types::ValueType.new(value.to_s) }

          rule(base_type: simple(:base_type), key_type: simple(:key_type), value_type: simple(:value_type)) { Types::GenericType.from_key_value(base_type, key_type, value_type) }
          rule(base_type: simple(:base_type), value_types: sequence(:value_types)) { Types::SequenceType.new(base_type, value_types) }
          rule(base_type: simple(:base_type), value_types: simple(:value_type)) { Types::SequenceType.new(base_type, [value_type]) }
          rule(base_type: simple(:base_type), type_arguments: sequence(:type_arguments)) { Types::GenericType.new(base_type, type_arguments) }

          rule(method_name: simple(:method_name)) { Types::DuckType.new(method_name) }
          rule(key_type: simple(:key_type), value_type: simple(:value_type)) { Types::GenericType.from_key_value(Types::InstanceType.new('::Hash'), key_type, value_type) }
          rule(value_types: sequence(:value_types)) { Types::SequenceType.new(Types::InstanceType.new('::Array'), value_types) }
          rule(value_types: simple(:value_type)) { Types::SequenceType.new(Types::InstanceType.new('::Array'), [value_type]) }
          rule(type_in_array: simple(:type)) { Types::GenericType.new(Types::InstanceType.new('::Array'), [type]) }

          rule(types: sequence(:types)) { Types::UnionType.new(types) }
          rule(types: simple(:type)) { type }
        end
      end
    end
  end
end
