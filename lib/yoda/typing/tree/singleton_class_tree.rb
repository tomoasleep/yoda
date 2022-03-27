require 'yoda/typing/tree/namespace_inferable'

module Yoda
  module Typing
    module Tree
      class SingletonClassTree < Base
        include NamespaceInferable

        # @!method node
        #   @return [AST::SingletonClassNode]

        # @return [Types::Type]
        def infer_type
          receiver_type = infer_child(node.receiver)

          new_context = context.derive_class_context(class_type: receiver_type.singleton_type)
          infer_child(node.body, context: new_context)

          generator.nil_type
        end
      end
    end
  end
end
