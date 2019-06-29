module Yoda
  module AST
    class BlockCallNode < Node
      # @return [Node]
      def send_clause
        children[0]
      end

      # @return [Node]
      def arguments_clause
        children[1]
      end

      # @return [Node]
      def body
        children[2]
      end
    end
  end
end
