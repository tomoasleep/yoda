module Yoda
  module AST
    class IfNode < Node
      # @return [Node]
      def assignee
        children[0]
      end

      # @return [Node]
      def collection
        children[1]
      end

      # @return [Node]
      def body
        children[2]
      end
    end
  end
end
