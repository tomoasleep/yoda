module Yoda
  module Parsing
    module AstTraversable
      # @param root_node [Array<::Parser::AST::Node>]
      # @param current_location [Parser::Source::Map]
      # @return [Array<::Parser::AST::Node>]
      def calc_nodes_to_current_location(root_node, current_location)
        nodes = [root_node]
        node = root_node
        while node && !node.children.empty?
          node = node.children.find { |n| n.respond_to?(:location) && current_location.included?(n.location) }
          nodes << node if node && node.is_a?(::Parser::AST::Node)
        end
        nodes
      end
    end
  end
end
