module Yoda
  module AST
    class LiteralNode < Node
      def children
        []
      end

      # @return [Object]
      def value
        node.children[0]
      end

      def inspect_content
        value
      end
    end
  end
end
