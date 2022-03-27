module Yoda
  module Typing
    module Tree
      class Ensure < Base
        # @!method node
        #   @return [AST::EnsureNode]

        # @return [Types::Type]
        def infer_type
          type = infer_child(node.body)
          infer_child(node.ensure_body)
          type
        end
      end
    end
  end
end
