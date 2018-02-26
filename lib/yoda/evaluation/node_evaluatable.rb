module Yoda
  module Evaluation
    module NodeEvaluatable
      # @param code_node   [::Parser::AST::Node]
      # @return [Model::Types::Base, nil]
      def calculate_type(code_node)
        calculate_trace(code_node)&.type
      end

      # @param code_node   [::Parser::AST::Node]
      # @return [Array<Store::Values::Base>]
      def calculate_values(code_node)
        trace = calculate_trace(code_node)
        trace ? trace.values : []
      end

      # @param code_node   [::Parser::AST::Node, nil]
      # @return [Typing::Traces::Base, nil]
      def calculate_trace(code_node)
        return nil unless code_node
        evaluator = scope_builder.create_evaluator
        evaluator.process(scope_builder.body_node)
        evaluator.find_trace(code_node)
      end

      # @param send_node [Parsing::NodeObjects::SendNode]
      # @return [Array<Symbol>]
      def method_visibility_of_send_node(send_node)
        if send_node.receiver_node
          %i(public)
        else
          %i(public private protected)
        end
      end

      # @param registry  [Store::Registry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Store::Objects::Base, nil]
      def find_context_object(registry, method_node)
        scope_builder.namespace
      end

      private

      # @abstract
      # @return [Parsing::NodeObjects::MethodDefinition, Parsing::NodeObjects::Namespace]
      def current_scope
        fail NotImplementedError
      end

      # @abstract
      # @return [Store::Registry]
      def registry
        fail NotImplementedError
      end

      # @return [ScopeBuilder]
      def scope_builder
        @scope_builder ||= ScopeBuilder.new(registry, current_scope)
      end

      class ScopeBulder
        # @return [Parsing::NodeObjects::MethodDefinition, Parsing::NodeObjects::Namespace]
        attr_reader :scope

        # @return [Store::Registry]
        attr_reader :registry

        # @param registry [Store::Registry]
        # @param scope    [Parsing::NodeObjects::MethodDefinition, Parsing::NodeObjects::Namespace]
        def initialize(registry, scope)
          @registry = registry
          @scope = scope
        end

        # @return [AST::Node]
        def body_node
          scope.body
        end

        # @return [Typing::Evaluator]
        def create_evaluator
          Typing::Evaluator.new(create_evaluation_context(registry, scope))
        end

        # @return [Typing::Context]
        def create_evaluation_context
          fail RuntimeError, "The namespace #{scope.namespace_name} (#{scope}) is not registered" unless namespace
          Typing::Context.new(registry, namespace, lexical_scope, create_evaluation_env)
        end

        # @return [Typing::Environment]
        def create_evaluation_env
          if signature
            method_object.parameters.parameter_names.each_with_object(Typing::Environment.new) { |name, env| env.bind(name.gsub(/:\Z/, ''), method_object.parameter_type_of(name)) }
          else
            Typing::Environment.new
          end
        end

        private

        # @return [Model::FunctionSignatures::Base, nil]
        def signature
          @signature ||= namespace && scope.is_a?(Parsing::NodeObjects::MethodDefinition) && Store::Query::FindSignature.new(registry).select(namespace, scope.name.to_s).first
        end

        # @return [Array<Path>]
        def lexical_scope
          @lexical_scope ||= namespace_scope.paths_from_root.reverse.map { |name| Model::Path.build(name.empty? ? 'Object' : name.gsub(/\A::/, '')) }
        end

        # @return [Store::Objects::Base, nil]
        def namespace
          @namespace ||= Store::Query::FindConstant.new(registry).find(namespace_scope.full_name)
        end

        # @return [Parsing::NodeObjects::Namespace]
        def namespace_scope
          scope.is_a?(Parsing::NodeObjects::MethodDefinition) ? scope.namespace : scope
        end
      end
    end
  end
end
