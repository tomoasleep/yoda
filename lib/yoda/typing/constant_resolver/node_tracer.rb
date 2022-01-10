module Yoda
  module Typing
    class ConstantResolver
      class NodeTracer
        # @return [AST::Node]
        attr_reader :node

        # @return [Inferencer::Tracer]
        attr_reader :tracer

        # @param node [AST::Node]
        # @param tracer [Inferencer::Tracer]
        def initialize(node:, tracer:)
          @node = node
          @tracer = tracer
        end

        # @param type [Types::Base]
        # @param context [Contexts::BaseContext]
        def bind_type(type:, context:)
          tracer.bind_type(node: node, type: type, context: context)
        end

        # @param context [Contexts::BaseContext]
        def bind_context(context:)
          tracer.bind_context(node: node, context: context)
        end

        # @param constants [Array<Store::Objects::Base>]
        def bind_constants(constants:)
          tracer.bind_constants(node: node, constants: constants)
        end
      end
    end
  end
end
