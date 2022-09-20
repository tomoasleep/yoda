module Yoda
  module Model
    # Parser for yard method signature.
    class YardSignatureParser
      class ParseError < StandardError; end

      # @param [String]
      attr_reader :signature

      # @param signature [String]
      def initialize(signature)
        @signature = signature
      end

      # @return [Array<Array(String, String)>]
      def to_a
        ast.parameters.parameter_clauses.map do |param_node|
          [format_parameter_name(param_node), param_node.optional_value&.unparse]
        end
      end

      private

      # @param param_node [Yoda::AST::OptionalParameterNode, Yoda::AST::ParameterNode]
      def format_parameter_name(param_node)
        if param_node.keyword_parameter?
          "#{param_node.content&.name}:"
        elsif param_node.rest_parameter?
          "*#{param_node.content&.name}"
        elsif param_node.keyword_rest_parameter?
          "**#{param_node.content&.name}"
        elsif param_node.block_parameter?
          "&#{param_node.content&.name}"
        elsif param_node.forward_parameter?
          "..."
        else
          param_node.content&.name
        end
      end

      # @return [Yoda::AST::DefNode]
      def ast
        fail ParseError, "Invalid signature: #{signature}" unless signature&.start_with?(/\s*def\s/)
        @ast ||= Yoda::Parsing.parse("#{signature};end")
      rescue Parser::SyntaxError => e
        fail ParseError, e.message
      end
    end
  end
end
