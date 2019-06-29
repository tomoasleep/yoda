module Yoda
  module AST
    class InterpolationTextNode < Node
      # @return [Array<Vnode>]
      def contents
        children
      end
    end
  end
end
