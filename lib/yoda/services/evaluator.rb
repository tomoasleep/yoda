require 'forwardable'

module Yoda
  module Services
    class Evaluator
      extend Forwardable

      # @return [AST::Vnode]
      attr_reader :ast

      # @return [Store::Registry]
      attr_reader :registry

      # @return [Typing::Inferencer]
      attr_reader :inferencer

      delegate %i(type type_expression context_variable_types receiver_candidates method_candidates node_info) => :tracer

      # @param ast [::Parser::AST::Node]
      # @param registry [Store::Registry]
      def initialize(ast:, registry:)
        @ast = ast
        @registry = registry
        @inferencer = Typing::Inferencer.create_for_root(registry)
        @lock = Concurrent::ReadWriteLock.new
      end

      # @return [Typing::Inferencer::Tracer]
      def tracer
        @lock.with_write_lock do
          @tracer ||= begin
            inferencer.infer(ast)
            inferencer.tracer
          end
        end
      end
    end
  end
end
