module Yoda
  module Evaluation
    module NodeEvaluatable
      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Registry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Store::Types::Base, nil]
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
        _type, tyenv = evaluator.process(current_method.body_node, create_evaluation_env(registry, method_node))
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
      # @param method_node [Parsing::NodeObjects::MethodNode]
      # @return [Typing::Context]
      def create_evaluation_context(registry, method_node)
        value = method_node.caller_value(registry)
        Typing::Context.new(registry, value)
      end

      # @param method_node [Parsing::NodeObjects::MethodNode]
      # @return [Typing::Environment]
      def create_evaluation_env(registry, method_node)
        method_object = registry.find(method_node.full_name)
        fail RuntimeError, "The function #{method_node.full_name} (#{method_node}) is not registered" unless method_object
        function = Store::Functions::Method.new(method_object)
        env = Typing::Environment.new
        function.type.parameters.each do |name, type, _default|
          name = name.gsub(/:\Z/, '')
          env.bind(name, type)
        end
        env
      end
    end
  end
end
