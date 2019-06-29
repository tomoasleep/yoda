module Yoda
  module AST
    class PairNode < Node
      # @return [Vnode]
      def key
        children[0]
      end

      # @return [Vnode]
      def value
        children[1]
      end
    end
  end
end
