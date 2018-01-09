require 'parser/current'

module Yoda
  module Parsing
    class Parser
      # @param string [String]
      # @return [::Parser::AST::Node]
      def parse(string)
        ::Parser::CurrentRuby.parse(string)
      end

      # @param node [::AST::Node]
      def type_of(node)
        node.type
      end
    end
  end
end
