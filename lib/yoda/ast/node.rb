require 'forwardable'

module Yoda
  module AST
    class Node < Vnode
      extend Forwardable

      # @return [Parser::AST::Node]
      attr_reader :node

      # @return [Symbol]
      delegate type: :node
      
      # @param node [Parser::AST::Node]
      # @param parent [Vnode]
      def initialize(node, parent: nil)
        @node = node
        super(parent: parent)
      end

      # @return [Array<Vnode>]
      def children
        @children ||= node.children.map(&method(:wrap_child))
      end

      # @return [String]
      def identifier
        "#{type}:#{source_map ? source_map.expression : object_id}"
      end
      
      # @return [Parser::Source::Map, nil]
      def source_map
        node.location
      end
    end
  end
end
