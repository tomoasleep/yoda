module Yoda
  module AST
    class IfNode < Node
      # @return [Node]
      def condition
        children[0]
      end

      # @return [Node]
      def then_clause
        children[1]
      end

      # @return [Node]
      def else_clause
        children[2]
      end
    end
  end
end
