module Yoda
  module Typing
    module Tree
      class Variable < Base
        # @!method node
        #   @return [AST::VariableNode]

        # @return [Types::Type]
        def infer_type
          context.type_binding.resolve(node.name) || generator.any_type
        end
      end
    end
  end
end
