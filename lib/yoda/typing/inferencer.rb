module Yoda
  module Typing
    class Inferencer
      require 'yoda/typing/inferencer/arguments_binder'
      require 'yoda/typing/inferencer/arguments'
      require 'yoda/typing/inferencer/method_resolver'
      require 'yoda/typing/inferencer/object_resolver'
      require 'yoda/typing/inferencer/parameter_binder'
      require 'yoda/typing/inferencer/tracer'
      require 'yoda/typing/inferencer/type_binding'

      # @return [Contexts::BaseContext]
      attr_reader :context

      # @return [Tracer]
      attr_reader :tracer

      # @param environment [Model::Environment]
      # @return [Inferencer]
      def self.create_for_root(environment:)
        context = Contexts.root_scope(environment: environment)
        new(context: context)
      end

      # @param context [Contexts::BaseContext]
      # @param tracer [Tracer, nil]
      def initialize(context:, tracer: nil)
        @context = context
        @tracer = tracer || Tracer.new(environment: context.environment, generator: context.generator)
      end

      # @param node [AST::Vnode]
      # @return [Store::Types::Base]
      def infer(node)
        # AstTraverser.new(tracer: tracer, context: context).traverse(node)
        Tree.build(node, context: context, tracer: tracer).type
      end

      # @param pp [PP]
      def pretty_print(pp)
        pp.object_group(self) do
          pp.breakable
          pp.text "@context="
          pp.pp context
          pp.comma_breakable
          pp.text "@tracer="
          pp.pp tracer
        end
      end
    end
  end
end
