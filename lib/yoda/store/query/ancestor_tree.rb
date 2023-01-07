require 'set'

module Yoda
  module Store
    module Query
      class AncestorTree
        # @return [Registry]
        attr_reader :registry

        # @return [Objects::NamespaceObject]
        attr_reader :object

        # @return [Visitor]
        attr_reader :base_visitor

        # @param object [Objects::NamespaceObject]
        # @param registry [Registry]
        def initialize(registry:, object:, visitor: Visitor.new)
          @registry = registry
          @object = object
          @base_visitor = visitor
        end

        def ancestors(**kwargs)
          Enumerator.new do |yielder|
            walk_ancestors(yielder, visitor: base_visitor.fork, **kwargs)
          end
        end

        # @return [Enumerator<Objects::NamespaceObject>]
        def mixins
          Enumerator.new do |yielder|
            object.mixin_addresses.each do |address|
              if el = registry.get(address.to_s)
                yielder << el
              end
            end
          end
        end

        # @return [AncestorTree, nil]
        def parent
          @parent ||= superclass && AncestorTree.new(registry: registry, object: superclass, visitor: base_visitor.fork)
        end

        # @return [Objects::NamespaceObject, nil]
        def superclass
          return @superclass if instance_variable_defined?(:@superclass)
          @superclass = begin
            found_object = begin
              if object.respond_to?(:base_class_address)
                base_class_superclass
              elsif object.respond_to?(:superclass_path)
                if object.superclass_path
                  Logger.trace("find superclass (#{object.superclass_path}) of #{object.address}")
                  FindConstant.new(registry).find(object.superclass_path, visitor: base_visitor.fork)
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
        def walk_ancestors(yielder, visitor:, include_self: true)
          if include_self
            visitor.visit("AncestorTree.walk_ancestors(#{object.address})")
            yielder << object
          end

          mixins.each { |mixin| yielder << mixin }

          return unless parent
          parent.walk_ancestors(yielder, visitor: visitor, include_self: true)
        end

        private

        # @return [Objects::NamespaceObject, nil]
        def base_class_superclass
          base_class = registry.get(object.base_class_address)
          if base_class && base_class.respond_to?(:superclass_path) && base_class.superclass_path
            Logger.trace("find superclass (#{base_class.superclass_path}) of base_class (#{base_class.address})")
            FindMetaClass.new(registry).find(base_class.superclass_path, visitor: base_visitor.fork)
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
