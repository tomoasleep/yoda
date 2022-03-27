module Yoda
  module Typing
    module Tree
      class LocalExit < Base
        # @!method node
        #   @return [AST::SpecialCallNode]

        def infer_type
          # TODO
          node.arguments[0] ? infer_child(node.arguments[0]) : generator.nil_type
        end
      end
    end
  end
end
