require 'yoda/typing/contexts/base_context'

module Yoda
  module Typing
    module Contexts
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
    end
  end
end
