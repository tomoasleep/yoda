module Yoda
  module Typing
    module Tree
      class ConditionalLoop < Base
        # @!method node
        #   @return [AST::ConditionalLoopNode]

        def infer_type
          # TODO
          infer_child(node.body)
        end
      end
    end
  end
end
