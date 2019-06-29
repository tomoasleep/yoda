module Yoda
  module AST
    class ArrayNode < Node
      # @return [Array<Vnode>]
      def contents
        children
      end
    end
  end
end
