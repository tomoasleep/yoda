module Yoda
  module AST
    class DefNode < Node
      # @return [Node]
      def name
        children[0]
      end

      # @return [Node]
      def arguments
        children[1]
      end

      # @return [Node]
      def body
        children[2]
      end
    end
  end
end
