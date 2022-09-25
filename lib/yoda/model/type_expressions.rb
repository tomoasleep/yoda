require 'parslet'
require 'yoda/model/yard_type_parser'

module Yoda
  module Model
    # Each type expression represents type annotations.
    # Unlike type for symbolic execution, each type expression has {LexicalScope}
    # and the corresponding constants are not determined yet.
    module TypeExpressions
      require 'yoda/model/type_expressions/base'
      require 'yoda/model/type_expressions/any_type'
      require 'yoda/model/type_expressions/value_type'
      require 'yoda/model/type_expressions/instance_type'
      require 'yoda/model/type_expressions/function_type'
      require 'yoda/model/type_expressions/generator'
      require 'yoda/model/type_expressions/duck_type'
      require 'yoda/model/type_expressions/module_type'
      require 'yoda/model/type_expressions/sequence_type'
      require 'yoda/model/type_expressions/self_type'
      require 'yoda/model/type_expressions/generic_type'
      require 'yoda/model/type_expressions/union_type'
      require 'yoda/model/type_expressions/unknown_type'
      require 'yoda/model/type_expressions/void_type'

      # @param string [String]
      # @return [TypeExpressions::Base]
      def self.parse(string)
        Generator.new.apply(YardTypeParser.new.parse(string))
      rescue Parslet::ParseFailed => failure
        TypeExpressions::UnknownType.new(string)
      end

      # @param strings [Array<String>]
      # @return [TypeExpressions::Base]
      def self.parse_type_strings(strings)
        TypeExpressions::UnionType.new(strings.map { |string| parse(string) })
      end

      # @param tag [Store::Objects::Tag]
      # @return 
      def self.from_tag(tag)
        Model::TypeExpressions.parse_type_strings(tag.yard_types || []).change_root(tag.lexical_scope.map { |literal| Model::Path.new(literal) } + [Model::Path.new('Object')])
      end
    end
  end
end
