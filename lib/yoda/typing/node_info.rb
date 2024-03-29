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

      delegate %i(location range) => :node

      # @param node [AST::Node]
      # @param tracer [Inferencer::Tracer]
      def initialize(node:, tracer:)
        @node = node
        @tracer = tracer
      end

      # @return [Symbol]
      def kind
        tracer.kind(node) || node.type
      end

      # @return [Types::Type]
      def receiver_type
        tracer.receiver_type(node)
      end

      # @return [Array<FunctionSignatures::Base>]
      def method_candidates
        tracer.method_candidates(node)
      end

      # @return [Array<Store::Objects::Base>]
      def constants
        tracer.constants(node)
      end

      # @return [Array<String>]
      def require_paths
        tracer.require_paths(node)
      end

      # @return [Types::Type]
      def type
        tracer.type(node)
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
      def lexical_scope_types
        context&.lexical_scope_types || []
      end

      # @param path_expr [String]
      # @return [Types::Type, nil]
      def resolve_constant(path_expr)
        context&.constant_resolver&.resolve_path(path_expr.to_s)
      end

      private

      # @return [Contexts::BaseContext]
      def context
        tracer.context(node)
      end
    end
  end
end
