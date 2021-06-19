module Yoda
  module AST
    class RescueNode < Node
      # @return [Node]
      def body
        children[0]
      end

      # @return [Array<RescueClauseNode>]
      def rescue_clauses
        children[1..-2]
      end

      # @return [Node]
      def else_clause
        children[-1]
      end
    end
  end
end
