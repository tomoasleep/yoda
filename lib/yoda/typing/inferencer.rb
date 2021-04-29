module Yoda
  module Typing
    class Inferencer
      require 'yoda/typing/inferencer/arguments_binder'
      require 'yoda/typing/inferencer/arguments'
      require 'yoda/typing/inferencer/ast_traverser'
      require 'yoda/typing/inferencer/contexts'
      require 'yoda/typing/inferencer/environment'
      require 'yoda/typing/inferencer/constant_resolver'
      require 'yoda/typing/inferencer/method_resolver'
      require 'yoda/typing/inferencer/method_definition_resolver'
      require 'yoda/typing/inferencer/object_resolver'
      require 'yoda/typing/inferencer/tracer'

      # @return [BaseContext]
      attr_reader :context

      # @return [Tracer]
      attr_reader :tracer

      # @param registry [Store::Registry]
      # @return [Inferencer]
      def self.create_for_root(registry)
        new(context: NamespaceContext.root_scope(registry))
      end

      # @param context [BaseContext]
      # @param tracer [Tracer, nil]
      def initialize(context:, tracer: nil)
        @context = context
        @tracer = tracer || Tracer.new(registry: context.registry)
      end

      # @param node [AST::Vnode]
      # @return [Store::Types::Base]
      def infer(node)
        AstTraverser.new(tracer: tracer, context: context).traverse(node)
      end
    end
  end
end
