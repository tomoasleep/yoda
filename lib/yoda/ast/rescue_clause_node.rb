module Yoda
  module AST
    class RescueClauseNode < Node
      # @return [Node]
      def match_clause
        children[0]
      end

      # @return [Node]
      def assignee
        children[1]
      end

      # @return [Node]
      def body
        children[2]
      end
    end
  end
end
