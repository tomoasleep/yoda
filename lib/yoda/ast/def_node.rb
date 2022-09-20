module Yoda
  module AST
    class DefNode < Node
      # @return [Symbol]
      delegate name: :name_clause

      # @return [NameVnode]
      def name_clause
        children[0]
      end

      # @return [ParametersNode]
      def parameters
        children[1]
      end

      # @return [Vnode]
      def body
        children[2]
      end

      def method?
        true
      end
    end
  end
end
