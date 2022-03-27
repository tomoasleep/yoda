module Yoda
  module Typing
    module Tree
      module NamespaceInferable
        # @!method node
        #   @return [AST::ModuleNode, AST::ClassNode]

        # @return [Types::Type]
        def infer_namespace
          namespace_type = infer_child(node.receiver)

          new_context = context.derive_class_context(class_type: namespace_type)
          infer_child(node.body, context: new_context)

          namespace_type
        end
      end
    end
  end
end
