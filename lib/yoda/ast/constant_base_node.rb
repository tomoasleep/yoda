module Yoda
  module AST
    class ConstantNode < Node
      # @return [Vnode, nil]
      def parent
        nil
      end
    end
  end
end
