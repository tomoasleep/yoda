module Yoda
  module AST
    class Vnode
      # @return [Array<Node>, nil]
      def children
        fail NotImplementedError
      end

      # @return [Symbol]
      def type
        fail NotImplementedError
      end

      # @return [String]
      def identifier
        "#{type}:#{object_id}"
      end
    end
  end
end
