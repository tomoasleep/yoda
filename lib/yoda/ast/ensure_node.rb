module Yoda
  module AST
    class EnsureNode < Node
      # @return [Node]
      def body
        children[0]
      end

      # @return [Node]
      def ensure_body
        children[1]
      end
    end
  end
end
