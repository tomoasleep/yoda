module Yoda
  module Typing
    module Tree
      class Case < Base
        # @!method node
        #   @return [AST::CaseNode]

        # @return [Type::Type]
        def infer_type
          subject_node, *when_nodes, else_node = node.children
          infer_child(subject_node)
          when_body_nodes = when_nodes.map { |node| node.children.last }
          generator.union_type(*[*when_body_nodes, else_node].compact.map { |node| infer_child(node) })
        end
      end
    end
  end
end
