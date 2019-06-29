module Yoda
  module AST
    class BlockNode < Node
      # @return [Node]
      def content
        children[0]
      end
    end
  end
end
