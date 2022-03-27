module Yoda
  module Typing
    module Tree
      class VariableAssignment < Base
        # @!method node
        #   @return [AST::AssignmentNode]

        # @return [Store::Types::Base]
        def infer_type
          context.type_binding.bind(node.assignee.name, body_type)
          body_type
        end

        # @return [Types::Type]
        def body_type
          @body_type ||= begin
            infer_child(node.content)
          end
        end
      end
    end
  end
end
