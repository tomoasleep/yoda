module Yoda
  module Typing
    module Tree
      class If < Base
        def type
          infer_branch_nodes(node.children.slice(1..2).compact)
        end

        # @param node [Array<::AST::Node>]
        # @return [Types::Base]
        def infer_branch_nodes(nodes)
          Types::Union.new(nodes.map { |node| infer(node) })
        end
      end
    end
  end
end
