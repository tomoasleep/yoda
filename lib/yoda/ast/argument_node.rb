module Yoda
  module AST
    class ArgumentNode < Node
      # @return [NameVnode, nil]
      def content
        children[0]
      end
    end
  end
end
