module Yoda
  module AST
    class LeftOperatorNode < Node
      # @return [Symbol]
      def operator
        type
      end

      # @return [Node]
      def content
        children[0]
      end
    end
  end
end
