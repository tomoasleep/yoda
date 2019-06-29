module Yoda
  module AST
    class HashNode < Node
      # @return [Array<Vnode>]
      def contents
        children
      end
    end
  end
end
