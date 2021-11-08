require 'yoda/typing/inferencer/tracer/masked_map'

module Yoda
  module Typing
    class Inferencer
      class Tracer
        class ContextTracer
          def initialize
            @node_to_context = MaskedMap.new
          end

          # @param node [AST::Node]
          # @param context [Contexts::BaseContext]
          def bind(node, context)
            @node_to_context[node.identifier] = context
          end

          # @param node [AST::Node]
          # @return [Contexts::BaseContext, nil]
          def context(node)
            @node_to_context[node.identifier]
          end

          # @param node [AST::Node]
          # @return [Hash{ Symbol => Types::Base }]
          def context_variable_types(node)
            context(node)&.type_binding&.all_variables || {}
          end

          # @param node [AST::Node]
          # @return [Hash{ Symbol => Store::Objects::Base }]
          def context_variable_objects(node)
            context(node)&.type_binding&.all_variables&.transform_values { |type| type.value.referred_objects } || {}
          end
        end
      end
    end
  end
end
