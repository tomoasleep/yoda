module Yoda
  module AST
    class NameVnode < Vnode
      # @return [Symbol]
      def type
        :name
      end

      # @return [Symbol]
      attr_reader :name

      # @param name [Symbol]
      def initialize(name, **kwargs)
        @name = name
        super(**kwargs)
      end

      # @return [Array<Node>, nil]
      def children
        []
      end

      def inspect_content
        name
      end
    end
  end
end
