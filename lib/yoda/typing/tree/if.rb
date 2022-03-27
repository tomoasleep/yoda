module Yoda
  module Typing
    module Tree
      class If < Base
        # @!method node
        #   @return [AST::IfNode]

        # @return [Types::Type]
        def infer_type
          infer_branch_nodes(node.children.first, node.children.slice(1..2).compact)
        end

        # @param branch_nodes [Array<::AST::Node>]
        # @return [Types::Base]
        def infer_branch_nodes(condition_node, branch_nodes)
          infer_child(condition_node)
          generator.union_type(*branch_nodes.map { |node| infer_child(node) })
        end
      end
    end
  end
end
