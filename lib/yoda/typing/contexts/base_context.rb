module Yoda
  module Typing
    module Contexts
      # @abstract
      class BaseContext
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Types::Base]
        attr_reader :receiver

        # @return [Store::Values::Base]
        attr_reader :namespace

        # @return [Environment]
        attr_reader :environment

        # @return [BaseContext, nil]
        attr_reader :parent

        # @param registry      [Store::Registry]
        # @param receiver      [Types::Base] represents who is self of the code.
        # @param parent        [BaseContext, nil]
        # @param binds         [Hash{Symbol => Types::Base}, nil]
        # @param lexical_scope [Hash{Symbol => Types::Base}, nil]
        def initialize(registry:, receiver:, parent: nil, binds: nil)
          fail TypeError, receiver unless receiver.is_a?(Types::Base)

          @registry = registry
          @receiver = receiver
          @parent = parent
          @environment = Inferencer::Environment.new(parent: parent_for_environment&.environment, binds: binds)
        end

        # @abstract
        # @return [Context, nil]
        def parent_for_environment
          fail NotImplementedError
        end

        def instance_type
          if respond_to?(:path)

          elsif parent
            parent.instance_type
          else
            fail NotImplementedError
          end
        end

        # Candidates of self objects
        # @return [Array<Store::Objects::NamespaceObject>]
        def current_objects
          parent&.current_objects || []
        end

        # @return [BaseContext]
        def current_namespace_context
          parent&.current_namespace_context
        end

        # @return [Array<Store::Objects::NamespaceObject>]
        def lexical_scope_objects
          (current_namespace_context.parent&.lexical_scope_objects || []) + current_objects
        end
      end
    end
  end
end
