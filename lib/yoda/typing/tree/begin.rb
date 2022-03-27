module Yoda
  module Typing
    module Tree
      class Begin < Base
        # @!method node
        #   @return [AST::BlockNode]

        # @return [Types::Type]
        def infer_type
          node.children.map { |node| infer_child(node) }.last
        end
      end
    end
  end
end
