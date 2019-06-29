module Yoda
  module AST
    class ClassNode < Node
      # @return [ConstantNode]
      def receiver
        children[0]
      end

      # @return [Vnode]
      def super_class
        children[1]
      end

      # @return [Vnode]
      def body
        children[2]
      end
    end
  end
end
