module Yoda
  module AST
    class CenterOperatorNode < Node
      # @return [Symbol]
      def operator
        type
      end

      # @return [Node]
      def left_content
        children[0]
      end

      # @return [Node]
      def right_content
        children[1]
      end
    end
  end
end
