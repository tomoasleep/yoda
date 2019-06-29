module Yoda
  module AST
    class DefNode < Node
      # @return [Node]
      def receiver
        children[0]
      end

      # @return [Node]
      def name
        children[1]
      end

      # @return [Node]
      def arguments
        children[2]
      end

      # @return [Node]
      def body
        children[3]
      end
    end
  end
end
