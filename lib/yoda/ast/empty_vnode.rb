module Yoda
  module AST
    class EmptyVnode < Vnode
      def initialize(_el = nil, **kwargs)
        super(**kwargs)
      end

      # @return [Symbol]
      def type
        :empty
      end

      # @return [Array<Node>, nil]
      def children
        []
      end

      # @return [boolean]
      def empty?
        true
      end
    end
  end
end
