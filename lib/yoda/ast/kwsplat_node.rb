module Yoda
  module AST
    class KwsplatNode < Node
      # @return [Vnode]
      def content
        children.first
      end
    end
  end
end
