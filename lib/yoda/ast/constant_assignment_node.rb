module Yoda
  module AST
    class ConstantAssignmentNode < Node
      # @return [Node]
      def assignee_base
        children[0]
      end

      # @return [Node]
      def assignee_name
        children[1]
      end

      # @return [Node]
      def content
        children[2]
      end
    end
  end
end
