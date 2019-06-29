module Yoda
  module AST
    class ConditionalLoopNode < Node
      # @return [Node]
      def condition
        children[0]
      end

      # @return [Node]
      def body
        children[1]
      end
    end
  end
end
