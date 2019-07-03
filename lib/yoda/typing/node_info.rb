require 'forwardable'

module Yoda
  module Typing
    # Facade for information of the specified node traced on inference
    class NodeInfo
      extend Forwardable

      # @return [AST::Node]
      attr_reader :node

      # @return [Inferencer::Tracer]
      attr_reader :tracer

      delegate %i(type location range) => :node

      # @param node [AST::Node]
      # @param tracer [Inferencer::Tracer]
      def initialize(node:, tracer:)
        @node = node
        @tracer = tracer
      end

      # @return [Array<Store::Objects::NamespaceObject>]
      def receiver_candidates
        tracer.receiver_candidates(node)
      end

      # @return [Array<FunctionSignatures::Base>]
      def method_candidates
        tracer.method_candidates(node)
      end

      # @return [Model::TypeExpressions::Base]
      def type_expression
        tracer.type_expression(node)
      end

      # @return [Array<Store::Objects::Base>]
      def objects
        tracer.objects(node)
      end

      # @return [Array<Store::Objects::Base>]
      def scope_objects
        tracer.objects(node)
      end

      # @return [Array<Store::Objects::NamespaceObject>]
      def scope_nestings
        context.lexical_scope_objects
      end

      private

      # @return [Inferencer::BaseContext]
      def context
        tracer.context(node)
      end
    end
  end
end
