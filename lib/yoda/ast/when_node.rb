module Yoda
  module AST
    class WhenNode < Node
      # @return [Array<Node>]
      def matchers
        children.slice(0..-2) || []
      end

      # @return [Node]
      def body
        children.last
      end
    end
  end
end
