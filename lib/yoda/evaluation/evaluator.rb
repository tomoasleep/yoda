module Yoda
  module Evaluation
    class Evaluator
      # @return [Parsing::Scopes::Base]
      attr_reader :scope

      # @return [Store::Registry]
      attr_reader :registry

      # @param registry [Store::Registry]
      # @param ast [Parser::AST::Node]
      # @param location [Parsing::Location]
      # @return [Evaluator]
      def self.from_ast(registry, ast, location)
        from_root_scope(registry, Parsing::Scopes::Builder.new(ast).root_scope, location)
      end

      # @param registry [Store::Registry]
      # @param root_scope [Parsing::Scopes::Root]
      # @param location [Parsing::Location]
      # @return [Evaluator]
      def self.from_root_scope(registry, root_scope, location)
        new(registry, root_scope.find_evaluation_root_scope(location) || root_scope)
      end

      # @param registry [Store::Registry]
      # @param scope [Parsing::Scopes::Base]
      def initialize(registry, scope)
        @registry = registry
        @scope = scope
      end

      # @param code_node   [::Parser::AST::Node]
      # @return [Model::Types::Base, nil]
      def calculate_type(code_node)
        calculate_trace(code_node)&.type
      end

      # @param code_node   [::Parser::AST::Node]
      # @return [Array<Store::Objects::Base>]
      def calculate_values(code_node)
        trace = calculate_trace(code_node)
        trace ? trace.values : []
      end

      # @param code_node   [::Parser::AST::Node, nil]
      # @return [Typing::Traces::Base, nil]
      def calculate_trace(code_node)
        return nil unless code_node
        evaluate
        evaluator.find_trace(code_node)
      end

      # @return [Store::Objects::Base, nil]
      def scope_constant
        @scope_constant ||= begin
          Store::Query::FindConstant.new(registry).find(scope.scope_name)
        end
      end

      private

      def evaluate
        unless @evaluated
          evaluator.process(scope.body_node)
          @evaluated = true
        end
      end

      # @return [Typing::Evaluator]
      def evaluator
        @evaluator ||= Typing::Evaluator.new(evaluation_context)
      end

      # @return [Typing::Context]
      def evaluation_context
        @evaluation_context ||= begin
          fail RuntimeError, "The namespace #{scope.scope_name} (#{scope}) is not registered" unless scope_constant
          lexical_scope = Typing::LexicalScope.new(scope_constant, scope.ancestor_scopes)
          context = Typing::Context.new(registry: registry, caller_object: receiver, lexical_scope: lexical_scope)
          context.env.bind_method_parameters(current_method_signature) if current_method_signature
          context
        end
      end

      # @return [Model::FunctionSignatures::Base, nil]
      def current_method_signature
        return unless scope.kind == :method
        @current_method_signature ||= Store::Query::FindSignature.new(registry).select(scope_constant, scope.name.to_s)&.first
      end

      def receiver
        @receiver ||= begin
          if scope.kind == :method
            Store::Query::FindConstant.new(registry).find(scope.scope_name)
          else
            Store::Query::FindMetaClass.new(registry).find(scope.scope_name)
          end
        end
      end
    end
  end
end
