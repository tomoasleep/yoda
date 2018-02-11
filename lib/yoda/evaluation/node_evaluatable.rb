module Yoda
  module Evaluation
    module NodeEvaluatable
      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Registry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Model::Types::Base, nil]
      def calculate_type(code_node, registry, method_node)
        calculate_trace(code_node, registry, method_node)&.type
      end

      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Registry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Array<Store::Values::Base>]
      def calculate_values(code_node, registry, method_node)
        if code_node
          trace = calculate_trace(code_node, registry, method_node)
          trace ? trace.values : []
        else
          [method_node.caller_value(registry)]
        end
      end

      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Reggistry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Typing::Traces::Base, nil]
      def calculate_trace(code_node, registry, method_node)
        evaluator = create_evaluator(registry, method_node)
        _type, tyenv = evaluator.process(current_method.body_node)
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

      private

      # @param registry    [Store::Reggistry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Typing::Evaluator]
      def create_evaluator(registry, method_node)
        Typing::Evaluator.new(create_evaluation_context(registry, method_node))
      end

      # @param registry  [Store::Registry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Typing::Context]
      def create_evaluation_context(registry, method_node)
        namespace = find_namespace(registry, method_node)
        fail RuntimeError, "The namespace #{mehtod_node.namespace_name} (#{method_node}) is not registered" unless namespace
        Typing::Context.new(registry, namespace, method_node.namespace.paths_from_root, create_evaluation_env(registry, method_node))
      end

      # @param method_node [Parsing::NodeObjects::MethodNode]
      # @return [Typing::Environment]
      def create_evaluation_env(registry, method_node)
        method_object = find_method(registry, method_node)
        fail RuntimeError, "The function #{method_node.full_name} (#{method_node}) is not registered" unless method_object
        method_object.parameters.parameter_names.each_with_object(Typing::Environment.new) { |name, env| env.bind(name.gsub(/:\Z/, ''), method_object.parameter_type_of(name)) }
      end

      def find_namespace(registry, method_node)
        Store::Query::FindConstant.new(registry).find(method_node.namespace_name)
      end

      def find_method(registry, method_node)
        namespace = find_namespace(registry, method_node)
        namespace && Store::Query::FindMethod.new(registry).find(namespace, method_node.name)
      end
    end
  end
end
