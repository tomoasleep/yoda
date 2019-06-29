module Yoda
  module AST
    class ArgumentNode < Node
      # @return [Node]
      def content
        children[0]
      end

      # @return [Node]
      def optional_value
        children[1]
      end
    end
  end
end
