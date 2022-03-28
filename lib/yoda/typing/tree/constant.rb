module Yoda
  module Typing
    module Tree
      class Constant < Base
        # @!method node
        #  @return [AST::ConstantNode]

        def infer_type
          query = context.constant_resolver.build_query_for_node(node, tracer: tracer)
          if (base_query = query.base).is_a?(ConstantResolver::CodeQuery)
            base_query.result_type = infer_child(base_query.node)
          end

          context.constant_resolver.resolve(query)
        end
      end
    end
  end
end
