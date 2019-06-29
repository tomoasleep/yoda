module Yoda
  module AST
    class SpecialCallNode < Node
      # @return [Array<Node>]
      def arguments
        children
      end
    end
  end
end
