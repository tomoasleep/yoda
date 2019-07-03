module Yoda
  module AST
    class AssignmentNode < Node
      # @return [NameVnode]
      def assignee
        children[0]
      end

      # @return [Node]
      def content
        children[1]
      end
    end
  end
end
