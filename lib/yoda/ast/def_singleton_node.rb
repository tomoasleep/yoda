module Yoda
  module AST
    class DefSingletonNode < Node
      # @return [Symbol]
      delegate name: :name_clause

      # @return [Vnode]
      def receiver
        children[0]
      end

      # @return [NameVnode]
      def name_clause
        children[1]
      end

      # @return [ParametersNode]
      def parameters
        children[2]
      end

      # @return [Vnode]
      def body
        children[3]
      end

      def method?
        true
      end
    end
  end
end
