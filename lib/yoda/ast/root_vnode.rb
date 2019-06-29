module Yoda
  module AST
    class RootVnode < Vnode
      include Namespace

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param node [Parser::AST::Node]
      def initialize(node)
        @node = node
      end

      # @return [nil]
      def parent
        nil
      end

      # @return [Symbol]
      def type
        :root
      end

      # @return [Vnode]
      def content
        @content ||= wrap_child(node)
      end

      # @return [Array<Vnode>]
      def children
        [content]
      end

      # @return [String]
      def identifier
        "#{type}:#{source_map.expression}"
      end
      
      # @return [Parser::Source::Map, nil]
      def source_map
        node.location
      end
    end
  end
end

