module Yoda
  module Parsing
    # Traverser searches {AST::Node} with the given queries.
    class Traverser
      require 'yoda/parsing/traverser/query_interface'
      require 'yoda/parsing/traverser/matcher'
      require 'yoda/parsing/traverser/result_set'
      include QueryInterface

      # @return [::AST::Node]
      attr_reader :node

      # @param node [::AST::Node]
      def initialize(node)
        @node = node
      end

      # @return [Enumerable<::AST::Node>]
      def all_nodes
        all_nodes_for(node)
      end
    end
  end
end
