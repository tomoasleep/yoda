module Yoda
  module Typing
    module Tree
      class ClassTree < Base
        def type
          infer_namespace_node(node)
        end

        # @param node [::AST::Node]
        # @return [Types::Base]
        def infer_namespace_node(node)
          case node.type
          when :module
            name_node, block_node = node.children
          when :class
            name_node, _, block_node = node.children
          end
          constant_resolver = ConstantResolver.new(context: context, node: name_node)
          type = constant_resolver.resolve_constant_type
          block_context = NamespaceContext.new(objects: [constant_resolver.constant], parent: context, registry: context.registry, receiver: type)

          if block_node
            derive(context: block_context).infer(block_node)
          end

          type
        end
      end
    end
  end
end
