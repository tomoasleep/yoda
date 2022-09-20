require 'forwardable'

module Yoda
  module AST
    class Node < Vnode
      extend Forwardable

      # @return [Parser::AST::Node]
      attr_reader :node

      # @return [Symbol]
      delegate type: :node

      # @return [String]
      delegate to_s: :node
      
      # @param node [Parser::AST::Node]
      # @param parent [Vnode]
      # @param comment_by_node [Hash{Parser::AST::Node => Array<Parser::Source::Comment>}]
      def initialize(node, parent: nil, comments_by_node: {})
        @node = node
        super(parent: parent, comments_by_node: comments_by_node)
      end

      # @return [Array<Vnode>]
      def children
        @children ||= node.children.map(&method(:wrap_child))
      end

      # @return [String]
      def identifier
        "#{type}:#{source_map&.expression ? source_map_expression : object_id}"
      end
      
      # @return [Parser::Source::Map, nil]
      def source_map
        node.location
      end

      # @return [Symbol]
      def kind
        node.type
      end

      # @return (see Unparser.unparse)
      def unparse
        Unparser.unparse(node)
      end

      private

      def source_map_expression
        "#{source_map.expression.source_buffer.name}:(#{source_map.line},#{source_map.column})..(#{source_map.last_line},#{source_map.last_column})"
      end
    end
  end
end
