module Yoda
  module Typing
    module Tree
      class For < Base
        # @!method node
        #   @return [AST::ForNode]

        def infer_type
          # TODO
          infer_child(node.body)
        end
      end
    end
  end
end
