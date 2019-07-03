module Yoda
  module AST
    class BlockCallNode < Node
      # @return [SendNode]
      def send_clause
        children[0]
      end

      # @return [ParametersNode]
      def parameters
        children[1]
      end

      # @return [Vnode]
      def body
        children[2]
      end
    end
  end
end
