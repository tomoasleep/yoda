module Yoda
  module AST
    class SendNode < Node
      # @return [Node]
      def receiver
        children[0]
      end

      # @return [Node]
      def selector
        children[1]
      end

      # @return [Array<Node>]
      def arguments
        children.slice(2..-1)
      end
    end
  end
end
