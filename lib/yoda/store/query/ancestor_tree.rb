require 'set'

module Yoda
  module Store
    module Query
      class AncestorTree
        class CircularReferenceError < StandardError
          # @param circular_scope [Objects::NamespaceObject, nil]
          def initialize(circular_scope)
            super("#{circular_scope&.path} appears twice")
          end
        end

        # An wrapper of {Enumerator::Yielder} to detect circular references.
        # @private
        class Visitor
          # @param yielder [Enumerator::Yielder]
          def initialize(yielder)
            @yielder = yielder
          end

          def <<(object)
            @yielder << object
          end

          def meet(object)
            add_met(object)
            self << object
          end

          private

          def add_met(object)
            @met ||= Set.new
            fail CircularReferenceError, object if @met.include?(object)
            @met.add(object)
          end
        end

        # @return [Registry]
        attr_reader :registry

        # @return [Objects::NamespaceObject]
        attr_reader :object

        # @param object [Objects::NamespaceObject]
        # @param registry [Registry]
        def initialize(registry:, object:)
          @registry = registry
          @object = object
        end

        def ancestors(**kwargs)
          Enumerator.new do |yielder|
            walk_ancestors(Visitor.new(yielder), **kwargs)
          end
        end

        # @return [Enumerator<Objects::RbsTypes::NamespaceWithTypeAssignments>]
        def mixins
          Enumerator.new do |yielder|
            object.prepend_accesses.each do |access|
              if el = find_namespace(access)
                yielder << el
              end
            end
            object.include_accesses.each do |access|
              if el = find_namespace(access)
                yielder << el
              end
            end
          end
        end

        # @return [AncestorTree, nil]
        def parent
          @parent ||= superclass && AncestorTree.new(registry: registry, object: superclass)
        end

        # @return [Objects::NamespaceObject, nil]
        def superclass
          return @superclass if instance_variable_defined?(:@superclass)
          @superclass = begin
            found_object = begin
              case object.kind
              when :meta_class
                base_class_superclass
              when :class
                if object.superclass_access
                  find_namespace(object.superclass_access)
                else
                  nil
                end
              else
                nil
              end
            end

            found_object&.namespace? ? found_object : nil
          end
        end

        protected

        # @param visitor [Visitor]
        # @param include_self [Boolean]
        def walk_ancestors(visitor, include_self: true)
          visitor.meet(object) if include_self
          mixins.each { |mixin| visitor << mixin }

          if parent
            parent.walk_ancestors(visitor, include_self: true)
          end
        end

        private

        # @param namespace [Objects::NamespaceObject]
        # @param namespace_access [Objects::RbsTypes::NamespaceAccess]
        # @return [Objects::RbsTypes::NamespaceWithTypeAssignments, nil]
        def find_namespace(namespace_access)
          object = FindConstant.new(registry).find(namespace_access.address)
          object&.namespace? ? wrap_namespace(object, namespace_access) : nil
        end

        # @param namespace [Objects::NamespaceObject]
        # @param namespace_access [Objects::RbsTypes::NamespaceAccess]
        # @return [Objects::RbsTypes::NamespaceWithTypeAssignments]
        def wrap_namespace(namespace, namespace_access)
          namespace_access.wrap_namespace(namespace)
        end

        # @return [Objects::NamespaceObject, nil]
        def base_class_superclass
          base_class = registry.get(object.base_class_address)
          if base_class && base_class.respond_to?(:superclass_access) && base_class.superclass_access
            meta_class = FindMetaClass.new(registry).find(base_class.superclass_access.address)
          elsif base_class
            registry.get('Class')
          else
            nil
          end
        end
      end
    end
  end
end
