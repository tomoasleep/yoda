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
      # @param parent [Vnode]
      def initialize(name, parent: nil)
        @name = name
        super(parent: parent)
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
