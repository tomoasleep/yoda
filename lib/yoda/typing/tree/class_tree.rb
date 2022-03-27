require 'yoda/typing/tree/namespace_inferable'

module Yoda
  module Typing
    module Tree
      class ClassTree < Base
        include NamespaceInferable

        # @!method node
        #   @return [AST::ClassNode]

        # @return [Types::Base]
        def infer_type
          if super_class_node = node.super_class
            infer_child(super_class_node)
          end

          infer_namespace
        end
      end
    end
  end
end
