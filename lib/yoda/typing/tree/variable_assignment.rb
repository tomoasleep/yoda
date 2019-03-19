module Yoda
  module Typing
    module Tree
      class VariableAssignment < Base
        def process
          process_bind(node.children[0], node.children[1])
        end

        # @param var [Symbol]
        # @param body_node [::AST::Node]
        # @return [Store::Types::Base]
        def process_bind(var, body_node)
          body_type = infer(body_node)
          context.environment.bind(var, body_type)
          body_type
        end
      end
    end
  end
end
