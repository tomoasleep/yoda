require 'forwardable'

module Yoda
  module Services
    class Evaluator
      extend Forwardable

      # @return [AST::Vnode]
      attr_reader :ast

      # @return [Model::Environment]
      attr_reader :environment

      # @return [Typing::Inferencer]
      attr_reader :inferencer

      delegate %i(type context_variable_types receiver_type method_candidates node_info) => :tracer

      # @param ast [::Parser::AST::Node]
      # @param registry [Model::Environment]
      def initialize(ast:, environment:)
        @ast = ast
        @environment = environment
        @inferencer = Typing::Inferencer.create_for_root(environment: environment)
        @lock = Concurrent::ReadWriteLock.new
      end

      # @return [void]
      def evaluate
        tracer
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
