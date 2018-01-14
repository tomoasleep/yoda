module Yoda
  module Evaluation
    module NodeEvaluatable
      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Reggistry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Store::Types::Base]
      def calculate_type(code_node, registry, method_node)
        evaluator = create_evaluator(registry, method_node)
        _type, tyenv = evaluator.process(current_method.body_node, create_evaluation_env(method_node))
        receiver_type, _tyenv = evaluator.process(code_node, tyenv)
        receiver_type
      end

      # @param code_node   [::Parser::AST::Node, nil]
      # @param registry    [Store::Reggistry]
      # @param method_node [Parsing::NodeObjects::MethodDefinition]
      # @return [Array<Store::Values::Base>]
      def calculate_values(code_node, registry, method_node)
        [method_node.caller_value(registry)] unless code_node
        evaluator = create_evaluator(registry, method_node)
        _type, tyenv = evaluator.process(current_method.body_node, create_evaluation_env(method_node))
        receiver_values, _tyenv = evaluator.process_to_instanciate(code_node, tyenv)
        receiver_values
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
      def create_evaluation_env(method_node)
        function = Store::Function.new(registry.find(method_node.full_name))
        env = Typing::Environment.new
        function.parameter_types.each do |name, type|
          name = name.gsub(/:\Z/, '')
          env.bind(name, type)
        end
        env
      end
    end
  end
end
