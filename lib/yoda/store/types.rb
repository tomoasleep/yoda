require 'parslet'

module Yoda
  module Store
    module Types
      require 'yoda/store/types/base'
      require 'yoda/store/types/any_type'
      require 'yoda/store/types/constant_type'
      require 'yoda/store/types/instance_type'
      require 'yoda/store/types/duck_type'
      require 'yoda/store/types/key_value_type'
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
          rule(:constant_name) { match('[a-zA-Z0-9]') >> match('[a-zA-Z0-9_]').repeat }
          rule(:constant_full_name) { str('::').maybe >> (constant_name >> (str('::') | str('.'))).repeat >> constant_name }

          rule(:space) { match('\s').repeat(1) }
          rule(:space?) { space.maybe }

          rule(:constant_type) { constant_full_name.as(:constant) }
          rule(:key_value_type) { constant_full_name.as(:name) >> str('{') >> space? >> type.as(:key_type) >> space? >> str('=>') >> space? >> type.as(:value_type) >> space? >> str('}') }
          rule(:sequence_type) { constant_full_name.as(:name) >> str('(') >> space? >> types.as(:value_types) >> space? >> str(')') }
          rule(:generic_type) { constant_full_name.as(:name) >> (str('<') >> space? >> type >> space? >> str('>')).repeat(1).as(:type_arguments) }

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
          rule(constant: simple(:value)) { Types::ConstantType.new(value.to_s) }
          rule(name: simple(:name), key_type: simple(:key_type), value_type: simple(:value_type)) { Types::KeyValueType.new(name.to_s, key_type, value_type) }
          rule(name: simple(:name), value_types: sequence(:value_types)) { Types::SequenceType.new(name.to_s, value_types) }
          rule(name: simple(:name), value_types: simple(:value_type)) { Types::SequenceType.new(name.to_s, [value_type]) }
          rule(name: simple(:name), type_arguments: sequence(:type_arguments)) { Types::GenericType.new(name.to_s, type_arguments) }

          rule(method_name: simple(:method_name)) { Types::DuckType.new(method_name) }
          rule(key_type: simple(:key_type), value_type: simple(:value_type)) { Types::KeyValueType.new('::Hash', key_type, value_type) }
          rule(value_types: sequence(:value_types)) { Types::SequenceType.new('::Array', value_types) }
          rule(value_types: simple(:value_type)) { Types::SequenceType.new('::Array', [value_type]) }
          rule(type_in_array: simple(:type)) { Types::GenericType.new('::Array', [type]) }

          rule(types: sequence(:types)) { Types::UnionType.new(types) }
          rule(types: simple(:type)) { type }
        end
      end
    end
  end
end
