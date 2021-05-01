require 'yoda/typing/contexts/base_context'

module Yoda
  module Typing
    module Contexts
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
    end
  end
end
