require 'forwardable'

module Yoda
  module Services
    class Evaluator
      extend Forwardable

      # @return [::Parser::AST::Node]
      attr_reader :ast

      # @return [Store::Registry]
      attr_reader :registry

      delegate %i(type type_expression context_variable_types receiver_candidates method_candidates node_info) => :tracer

      # @param ast [::Parser::AST::Node]
      # @param registry [Store::Registry]
      def initialize(ast:, registry:)
        @ast = ast
        @registry = registry
      end

      # @return [Typing::Inferencer]
      def inferencer
        @inferencer ||= Typing::Inferencer.new(context: Typing::Inferencer::NamespaceContext.root_scope(registry))
      end

      # @return [Typing::Inferencer::Tracer]
      def tracer
        @tracer ||= begin
          inferencer.infer(ast)
          inferencer.tracer
        end
      end
    end
  end
end
