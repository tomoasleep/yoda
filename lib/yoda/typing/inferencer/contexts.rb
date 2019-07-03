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

        # @return [BaseContext, nil]
        attr_reader :parent

        # @param registry      [Store::Registry]
        # @param receiver      [Types::Base] represents who is self of the code.
        # @param parent        [BaseContext, nil]
        # @param binds         [Hash{Symbol => Types::Base}, nil]
        # @param lexical_scope [Hash{Symbol => Types::Base}, nil]
        def initialize(registry:, receiver:, parent: nil, binds: nil)
          fail TypeError, registry unless registry.is_a?(Store::Registry)
          fail TypeError, receiver unless receiver.is_a?(Types::Base)

          @registry = registry
          @receiver = receiver
          @parent = parent
          @environment = Environment.new(parent: parent_for_environment&.environment, binds: binds)
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

      # Block context which has its lexical scope (for instance_eval and instance_exec)
      class NamespaceBlockContext < BaseContext
        # @return [Store::Objects::NamespaceObject]
        attr_reader :objects

        # @param namespaces [Array<Store::Objects::NamespaceObject>] namespace objects which context resolution and method definition refer
        def initialize(objects:, **kwargs)
          @objects = objects
          super(**kwargs)
        end

        # @return [Array<Store::Objects::NamespaceObject>]
        def current_objects
          objects
        end

        # @return [BaseContext]
        def current_namespace_context
          self
        end

        # @return [Context, nil]
        def parent_for_environment
          parent
        end
      end

      class NamespaceContext < BaseContext
        # @return [NamespaceContext]
        def self.root_scope(registry)
          generator = Types::Generator.new(registry)
          object = Store::Query::FindConstant.new(registry).find('Object')
          object_meta = Store::Query::FindMetaClass.new(registry).find('Object') || Store::Objects::MetaClassObject.new(path: 'Object')
          new(objects: [object_meta], registry: registry, receiver: generator.object_type(object))
        end

        # @return [Store::Objects::NamespaceObject]
        attr_reader :objects

        # @param namespaces [Array<Store::Objects::NamespaceObject>] namespace objects which context resolution and method definition refer
        def initialize(objects:, **kwargs)
          @objects = objects
          super(**kwargs)
        end

        # @return [Array<Store::Objects::NamespaceObject>]
        def current_objects
          objects
        end

        # @return [BaseContext]
        def current_namespace_context
          self
        end

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
