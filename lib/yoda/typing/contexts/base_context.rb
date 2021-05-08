require 'forwardable'
require 'yoda/typing/contexts/context_derivation'

module Yoda
  module Typing
    module Contexts
      # @abstract
      class BaseContext
        extend Forwardable
        include ContextDerivation

        # @return [Model::Environment]
        attr_reader :environment

        # @return [Types::Type]
        attr_reader :receiver

        # @return [Types::Type]
        attr_reader :constant_ref

        # @return [BaseContext, nil]
        attr_reader :parent

        # @return [Inferencer::TypeBinding]
        attr_reader :type_binding

        delegate [:resolve_value_by_rbs_type]

        # @param environment   [Model::Environment]
        # @param receiver      [Types::Type] represents who is self of the code.
        # @param constant_ref  [Types::Type] represents who is self of the code.
        # @param parent        [BaseContext, nil]
        # @param binds         [Hash{Symbol => RBS::Types::t}, nil]
        def initialize(environment:, receiver:, constant_ref:, parent: nil, binds: nil)
          @environment = environment
          @receiver = receiver
          @constant_ref = constant_ref
          @parent = parent
          @type_binding = Inferencer::TypeBinding.new(parent: parent_variable_scope_context&.type_binding, binds: binds)
        end

        # @deprecated Use methods of {BaseContext} instead.
        def registry
          environment.registry
        end

        def method_receiver
          constant_ref.instance_type
        end

        # @abstract
        # @return [Context, nil]
        def parent_variable_scope_context
          fail NotImplementedError
        end

        # @return [Array<Types::Type>]
        def lexical_scope_types
          @lexical_scope_types ||= begin
            parent_types = parent&.lexical_scope_types || []
            if parent.nil?
              [constant_ref]
            elsif parent && constant_ref != parent.constant_ref
              parent_types + [constant_ref]
            else
              parent_types
            end
          end
        end

        # @return [Types::Generator]
        def generator
          Types::Generator.new(environment: environment)
        end
      end
    end
  end
end
