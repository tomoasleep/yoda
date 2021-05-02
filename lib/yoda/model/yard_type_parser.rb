require 'parslet'

module Yoda
  module Model
    class YardTypeParser < Parslet::Parser
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
  end
end
