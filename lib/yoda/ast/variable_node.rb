module Yoda
  module AST
    class VariableNode < Node
      # @return [NameVnode]
      def name_clause
        children[0]
      end

      # @return [Symbol]
      def name
        name_clause.name
      end
    end
  end
end
