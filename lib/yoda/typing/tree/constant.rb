module Yoda
  module Typing
    module Tree
      class Constant < Base
        # @!method node
        #  @return [AST::ConstantNode]

        def infer_type
          context.constant_resolver.resolve_node(node, tracer: tracer)
        end
      end
    end
  end
end
