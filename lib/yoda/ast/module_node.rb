module Yoda
  module AST
    class ModuleNode < Node
      include Namespace

      # @return [ConstantNode]
      def receiver
        children[0]
      end

      # @return [Vnode]
      def body
        children[1]
      end
    end
  end
end
