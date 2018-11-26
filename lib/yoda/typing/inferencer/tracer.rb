module Yoda
  module Typing
    class Inferencer
      class Tracer
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Types::Generator]
        attr_reader :generator

        # @return [Hash{ ::AST::Node => Types::Base }]
        attr_reader :node_to_type

        # @return [Hash{ ::AST::Node => Context }]
        attr_reader :node_to_context

        # @return [Hash{ ::AST::Node => Array<Store::Objects::NamespaceObject> }]
        attr_reader :node_to_receiver_candidates

        # @return [Hash{ ::AST::Node => Array<FunctionSignatures::Base> }]
        attr_reader :node_to_method_candidates

        # @param registry [Store::Registry]
        # @param generator [Types::Generator]
        def initialize(registry:, generator:)
          @registry = registry
          @generator = generator

          @node_to_type = {}
          @node_to_context = {}
          @node_to_method_candidates = {}
          @node_to_receiver_candidates = {}
        end

        # @param node [::AST::Node]
        # @param type [Types::Base]
        # @param context [BaseContext]
        def bind_type(node:, type:, context:)
          node_to_type[node.object_id] = type
        end

        # @param node [::AST::Node]
        # @param context [BaseContext]
        def bind_context(node:, context:)
          node_to_context[node.object_id] = context
        end

        # @param variable [Symbol]
        # @param type [Types::Base]
        # @param context [BaseContext]
        def bind_local_variable(variable:, type:, context:)
          context.environment.bind(variable, type)
        end

        # @param node [::AST::Node]
        # @param receiver_candidates [Array<Store::Objects::NamespaceObject>]
        # @param method_candidates [Array<Model::FunctionSignatures::Base>]
        def bind_send(node:, receiver_candidates:, method_candidates:)
          fail TypeError, receiver_candidates unless receiver_candidates.all? { |candidate| candidate.is_a?(Store::Objects::NamespaceObject) }
          fail TypeError, method_candidates unless method_candidates.all? { |candidate| candidate.is_a?(Model::FunctionSignatures::Base) }

          node_to_receiver_candidates[node.object_id] = receiver_candidates
          node_to_method_candidates[node.object_id] = method_candidates
        end

        # @param node [::AST::Node]
        # @return [Types::Base]
        def type(node)
          node_to_type[node.object_id] || Types::Any.new
        end

        # @param node [::AST::Node]
        # @return [NodeInfo]
        def node_info(node)
          NodeInfo.new(node: node, tracer: self)
        end

        # @param node [::AST::Node]
        # @return [Model::TypeExpressions::Base]
        def type_expression(node)
          type(node).to_expression
        end

        # @param node [::AST::Node]
        # @return [Array<Store::Objects::Base>]
        def objects(node)
          ObjectResolver.new(registry: registry, generator: generator).call(type(node))
        end

        # @param node [::AST::Node]
        # @return [Array<Store::Objects::NamespaceObject>]
        def receiver_candidates(node)
          node_to_receiver_candidates[node.object_id] || []
        end

        # @param node [::AST::Node]
        # @return [Array<FunctionSignatures::Base>]
        def method_candidates(node)
          node_to_method_candidates[node.object_id] || []
        end

        # @param node [::AST::Node]
        # @return [Hash{ Symbol => Types::Base }]
        def context_variable_types(node)
          current_context = node_to_context[node.object_id]
          current_context.environment.all_variables.transform_values(&:to_expression)
        end

        # @param node [::AST::Node]
        # @return [Hash{ Symbol => Store::Objects::Base }]
        def context_variable_objects(node)
          current_context = node_to_context[node.object_id]
          current_context.environment.all_variables.transform_values { |value| ObjectResolver.new(registry: registry, generator: generator).call(value) }
        end
      end
    end
  end
end
