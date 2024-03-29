module Yoda
  module Typing
    class Inferencer
      class Tracer
        # @return [Model::Environment]
        attr_reader :environment

        # @return [Types::Generator]
        attr_reader :generator

        # @return [Hash{ AST::Node => Symbol }]
        attr_reader :node_to_kind

        # @return [Hash{ AST::Node => Tree::Base }]
        attr_reader :node_to_tree

        # @return [Hash{ AST::Node => Types::Base }]
        attr_reader :node_to_type

        # @return [Hash{ AST::Node => Context }]
        attr_reader :node_to_context

        # @return [Hash{ AST::Node => Types::Type }]
        attr_reader :node_to_receiver_type

        # @return [Hash{ AST::Node => Array<FunctionSignatures::Base> }]
        attr_reader :node_to_method_candidates

        # @return [Hash{ AST::Node => Array<Store::Objects::Base> }]
        attr_reader :node_to_constants

        # @return [Hash{ AST::Node => Array<String> }]
        attr_reader :node_to_require_paths

        # @return [Hash{ AST::Node => Array<Diagnostics::Base> }]
        attr_reader :node_to_diagnostics

        class MaskedMap
          def initialize
            @content = {}
          end

          def [](key)
            @content[key]
          end

          def []=(key, value)
            @content[key] = value
          end

          def to_s
            inspect
          end

          def to_h
            @content
          end

          def values
            @content.values
          end

          def inspect
            "(#{@content.length} items)"
          end
        end

        # @param environment [Model::Environment]
        # @param generator [Types::Generator]
        def initialize(environment:, generator:)
          @environment = environment
          @generator = generator

          @node_to_kind = MaskedMap.new
          @node_to_tree = MaskedMap.new
          @node_to_type = MaskedMap.new
          @node_to_context = MaskedMap.new
          @node_to_method_candidates = MaskedMap.new
          @node_to_receiver_type = MaskedMap.new
          @node_to_constants = MaskedMap.new
          @node_to_require_paths = MaskedMap.new
          @node_to_diagnostics = MaskedMap.new
        end

        # @param node [AST::Node]
        # @param tree [Tree::Base]
        def bind_tree(node:, tree:)
          node_to_tree[node.identifier] = tree
        end

        # @param node [AST::Node]
        # @param type [Types::Base]
        # @param context [Contexts::BaseContext]
        def bind_type(node:, type:, context:)
          node_to_type[node.identifier] = type
        end

        # @param node [AST::Node]
        # @param context [Contexts::BaseContext]
        def bind_context(node:, context:)
          node_to_context[node.identifier] = context
        end

        # @param variable [Symbol]
        # @param type [Types::Base]
        # @param context [Contexts::BaseContext]
        def bind_local_variable(variable:, type:, context:)
          # nop
        end

        # @param node [AST::Node]
        # @param receiver_candidates [Array<Store::Objects::NamespaceObject>]
        # @param method_candidates [Array<Model::FunctionSignatures::Base>]
        def bind_send(node:, receiver_type:, method_candidates:)
          fail TypeError, method_candidates unless method_candidates.all? { |candidate| candidate.is_a?(Model::FunctionSignatures::Wrapper) }

          node_to_kind[node.identifier] = :send
          node_to_receiver_type[node.identifier] = receiver_type
          node_to_method_candidates[node.identifier] = method_candidates
        end

        # @param node [AST::Node]
        # @param method_candidates [Array<Model::FunctionSignatures::Base>]
        def bind_method_definition(node:, method_candidates:)
          fail TypeError, method_candidates unless method_candidates.all? { |candidate| candidate.is_a?(Model::FunctionSignatures::Wrapper) }

          node_to_kind[node.identifier] = :send
          node_to_method_candidates[node.identifier] = method_candidates
        end

        # @param node [AST::Node]
        # @param constants [Array<Store::Objects::Base>]
        def bind_constants(node:, constants:)
          node_to_constants[node.identifier] = constants
        end

        # @param node [AST::Node]
        # @param require_paths [Array<String>]
        def bind_require_paths(node:, require_paths:)
          node_to_require_paths[node.identifier] = require_paths
        end

        # @param node [AST::Node]
        # @param diagnostics [Array<Diagnostics::Base>]
        def bind_diagnostics(node:, diagnostics:)
          node_to_diagnostics[node.identifier] ||= []
          node_to_diagnostics[node.identifier].push(*diagnostics)
        end

        # @param node [AST::Node]
        # @return [Symbol, nil]
        def kind(node)
          node_to_kind[node.identifier]
        end

        # @param node [AST::Node]
        # @return [Tree::Base, nil]
        def tree(node)
          node_to_tree[node.identifier]
        end

        # @param node [AST::Node]
        # @return [Types::Type]
        def type(node)
          node_to_type[node.identifier] || generator.unknown_type(reason: "not traced")
        end

        # @param node [AST::Node]
        # @return [NodeInfo]
        def node_info(node)
          NodeInfo.new(node: node, tracer: self)
        end

        # @param node [AST::Node]
        # @return [Array<Store::Objects::Base>]
        def objects(node)
          type(node).value.referred_objects
        end

        # @param node [AST::Node]
        # @return [Types::Type]
        def receiver_type(node)
          node_to_receiver_type[node.identifier] || generator.unknown_type(reason: "not traced")
        end

        # @param node [AST::Node]
        # @return [Array<FunctionSignatures::Wrapper>]
        def method_candidates(node)
          node_to_method_candidates[node.identifier] || []
        end

        # @param node [AST::Node]
        # @return [Array<Store::Objects::Base>]
        def constants(node)
          node_to_constants[node.identifier] || []
        end

        # @param node [AST::Node]
        # @return [Array<String>]
        def require_paths(node)
          node_to_require_paths[node.identifier] || []
        end

        # @param node [AST::Node]
        # @return [Contexts::BaseContext, nil]
        def context(node)
          node_to_context[node.identifier]
        end

        # @param node [AST::Node]
        # @return [Array<Diagnostics::Base>]
        def diagnostics(node)
          node_to_diagnostics[node.identifier] || []
        end

        # @param node [AST::Node]
        # @return [Array<Diagnostics::Base>]
        def all_diagnostics
          node_to_diagnostics.values.flatten.compact
        end

        # @param node [AST::Node]
        # @return [Hash{ Symbol => Types::Base }]
        def context_variable_types(node)
          context(node)&.type_binding&.all_variables || {}
        end

        # @param node [AST::Node]
        # @return [Hash{ Symbol => Store::Objects::Base }]
        def context_variable_objects(node)
          context(node)&.type_binding&.all_variables&.transform_values { |type| type.value.referred_objects } || {}
        end
      end
    end
  end
end
