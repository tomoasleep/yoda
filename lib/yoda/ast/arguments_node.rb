module Yoda
  module AST
    class ArgumentsNode < Node
      # @return [Array<Node>]
      def argument_clauses
        children
      end
    end
  end
end
