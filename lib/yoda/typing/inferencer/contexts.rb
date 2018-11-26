module Yoda
  module Typing
    class Inferencer
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

        # @return [Context, nil]
        attr_reader :parent

        # @param registry      [Store::Registry]
        # @param receiver      [Types::Base] represents who is self of the code.
        # @param parent        [Context, nil]
        # @param binds         [Hash{Symbol => Types::Base}, nil]
        def initialize(registry:, receiver:, parent: nil, binds: nil)
          fail TypeError, registry unless registry.is_a?(Store::Registry)
          fail TypeError, receiver unless receiver.is_a?(Types::Base)

          @registry = registry
          @receiver = receiver
          @parent = parent
          @environment = Environment.new(parent: parent_for_environment&.environment, binds: binds)
        end

        # @param name [String]
        # @return [Types::Base]
        def resolve_const_name(name)
        end

        # @abstract
        # @return [Context, nil]
        def parent_for_environment
          fail NotImplementedError
        end
      end

      class NamespaceContext < BaseContext
        # @param path [Model::Path]
        def initialize(path:, **kwargs)
          @path = path
          super(**kwargs)
        end

        # @return [Model::Path]
        attr_reader :path

        # @return [Context, nil]
        def parent_for_environment
          nil
        end
      end

      class MethodContext < BaseContext
        # @return [Context, nil]
        def parent_for_environment
          nil
        end
      end

      class BlockContext < BaseContext
        # @return [Context, nil]
        def parent_for_environment
          parent
        end
      end
    end
  end
end
