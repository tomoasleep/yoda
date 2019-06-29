module Yoda
  module AST
    class ConstantNode < Node
      # @return [Node]
      def base
        children[0]
      end

      # @return [Node]
      def name
        children[1]
      end
    end
  end
end
