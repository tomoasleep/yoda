module Yoda
  module Typing
    module Tree
      class Variable < Base
        def type
          context.environment.resolve(node.children.first) || generator.any_type
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
