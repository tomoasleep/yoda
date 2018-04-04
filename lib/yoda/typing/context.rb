require 'set'

module Yoda
  module Typing
    class Context
      # @return [Store::Registry]
      attr_reader :registry

      # @return [Store::Objects::Base]
      attr_reader :caller_object

      # @return [LexicalScope]
      attr_reader :lexical_scope

      # @return [Environment]
      attr_reader :env

      # @return [TraceStore]
      attr_reader :trace_store

      # @param registry       [Store::Registry]
      # @param caller_object  [Store::Objects::Base] represents who is the evaluator of the code.
      # @param lexical_scope [Array<Path>] represents where the code presents.
      def initialize(registry:, caller_object:, lexical_scope:, env: Environment.new, parent: nil, trace_store: TraceStore.new)
        fail ArgumentError, registry unless registry.is_a?(Store::Registry)
        fail ArgumentError, caller_object unless caller_object.is_a?(Store::Objects::Base)
        fail ArgumentError, lexical_scope unless lexical_scope.is_a?(LexicalScope)

        @registry = registry
        @caller_object = caller_object
        @lexical_scope = lexical_scope
        @env = env
        @trace_store = trace_store
      end

      # @param registry       [Store::Registry]
      # @param caller_object  [Store::Objects::Base] represents who is the evaluator of the code.
      # @param lexical_scope [Array<Path>] represents where the code presents.
      # @return [self]
      def derive(caller_object: self.caller_object, lexical_scope: self.lexical_scope)
        self.class.new(registry: registry, caller_object: caller_object, lexical_scope: lexical_scope, parent: self, trace_store: trace_store)
      end

      # @param node  [::AST::Node]
      # @return [Trace::Base, nil]
      def find_trace(node)
        trace_store.find_trace(node)
      end

      # @param node  [::AST::Node]
      # @param trace [Trace::Base]
      def bind_trace(node, trace)
        trace_store.bind_trace(node, trace)
      end

      class TraceStore
        def initialize
          @traces = {}
        end

        # @param node  [::AST::Node]
        # @return [Trace::Base, nil]
        def find_trace(node)
          @traces[node.is_a?(::Parser::AST::Node) ? ParserNodeWrapper.new(node) : node]
        end

        # @param node  [::AST::Node]
        # @param trace [Trace::Base]
        def bind_trace(node, trace)
          @traces[node.is_a?(::Parser::AST::Node) ? ParserNodeWrapper.new(node) : node] = trace
        end

        class ParserNodeWrapper
          # @return [::Parser::AST::Node]
          attr_reader :node

          # @param node [::Parser::AST::Node]
          def initialize(node)
            @node = node
          end

          # @param another [Object]
          def eql?(another)
            another.is_a?(ParserNodeWrapper) &&
              node == another.node &&
              node.location == another.node.location
          end

          def hash
            [node, node.location].hash
          end
        end
      end
    end
  end
end
