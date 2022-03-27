module Yoda
  module Typing
    module Tree
      class LogicalAssignment < Base
        # @!method node
        #   @return [AST::AssignmentNode]

        # @return [Types::Type]
        def infer_type
          # TODO
          infer_child(node.content)
        end
      end
    end
  end
end
