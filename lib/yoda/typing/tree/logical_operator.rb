module Yoda
  module Typing
    module Tree
      class LogicalOperator < Base
        # @!method node
        #   @return [AST::LeftOperatorNode, AST::CenterOperatorNode]

        # @return [Types::Type]
        def infer_type
          # TODO
          generator.union_type(*node.children.map { |node| infer_child(node) })
        end
      end
    end
  end
end
