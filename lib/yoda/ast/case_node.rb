module Yoda
  module AST
    class CaseNode < Node
      # @return [Node]
      def target
        children[0]
      end

      # @return [Array<Node>]
      def when_clauses
        children.slice(1..-2) || []
      end

      # @return [Node]
      def else_clause
        children.last
      end
    end
  end
end
