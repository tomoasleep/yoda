module Yoda
  module Typing
    class Inferencer
      class Tracer
        require 'yoda/typing/inferencer/tracer/constants_tracer'
        require 'yoda/typing/inferencer/tracer/context_tracer'
        require 'yoda/typing/inferencer/tracer/kind_tracer'
        require 'yoda/typing/inferencer/tracer/masked_map'
        require 'yoda/typing/inferencer/tracer/method_tracer'
        require 'yoda/typing/inferencer/tracer/type_tracer'

        extend Forwardable

        # @return [Model::Environment]
        attr_reader :environment

        # @return [Types::Generator]
        attr_reader :generator

        # @return [KindTracer]
        attr_reader :kind_tracer

        delegate :kind => :kind_tracer

        # @return [TypeTracer]
        attr_reader :type_tracer

        delegate [:type, :objects] => :type_tracer

        # @return [MethodTracer]
        attr_reader :method_tracer

        delegate [:method_candidates, :receiver_type] => :method_tracer

        # @return [ContextTracer]
        attr_reader :context_tracer

        delegate [:context, :context_variable_types, :context_variable_objects] => :context_tracer

        # @return [ConstantsTracer]
        attr_reader :constants_tracer

        delegate [:constants] => :constants_tracer


        # @param environment [Model::Environment]
        # @param generator [Types::Generator]
        def initialize(environment:, generator:)
          @environment = environment
          @generator = generator

          @kind_tracer = KindTracer.new
          @type_tracer = TypeTracer.new(generator: generator)
          @method_tracer = MethodTracer.new(generator: generator)
          @context_tracer = ContextTracer.new
          @constants_tracer = ConstantsTracer.new
        end

        # @param node [AST::Node]
        # @param type [Types::Base]
        # @param context [Contexts::BaseContext]
        def bind_type(node:, type:, context:)
          type_tracer.bind(node, type)
        end

        # @param node [AST::Node]
        # @param context [Contexts::BaseContext]
        def bind_context(node:, context:)
          context_tracer.bind(node, context)
        end

        # @param variable [Symbol]
        # @param type [Types::Base]
        # @param context [Contexts::BaseContext]
        def bind_local_variable(variable:, type:, context:)
          # nop
        end

        # @param node [AST::Node]
        # @param receiver_type [Types::Type]
        # @param method_candidates [Array<Model::FunctionSignatures::Base>]
        def bind_send(node:, receiver_type:, method_candidates:)
          fail TypeError, method_candidates unless method_candidates.all? { |candidate| candidate.is_a?(Model::FunctionSignatures::Wrapper) }

          kind_tracer.bind(node, :send)
          method_tracer.bind_send(node, receiver_type, method_candidates)
        end

        # @param node [AST::Node]
        # @param method_candidates [Array<Model::FunctionSignatures::Base>]
        def bind_method_definition(node:, method_candidates:)
          fail TypeError, method_candidates unless method_candidates.all? { |candidate| candidate.is_a?(Model::FunctionSignatures::Wrapper) }

          # FIXME: Use :def
          kind_tracer.bind(node, :send)
          method_tracer.bind_method(node, method_candidates)
        end

        # @param node [AST::Node]
        # @param constants [Array<Store::Objects::Base>]
        def bind_constants(node:, constants:)
          constants_tracer.bind(node, constants)
        end

        # @param node [AST::Node]
        # @return [NodeInfo]
        def node_info(node)
          NodeInfo.new(node: node, tracer: self)
        end
      end
    end
  end
end
