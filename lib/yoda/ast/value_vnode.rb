module Yoda
  module AST
    class ValueVnode < Vnode
      # @return [Symbol]
      def type
        :value
      end

      # @return [Object]
      attr_reader :value

      # @param value [Object]
      def initialize(name, **kwargs)
        @value = value
        super(**kwargs)
      end

      # @return [Array<Node>, nil]
      def children
        []
      end

      def inspect_content
        value
      end
    end
  end
end
