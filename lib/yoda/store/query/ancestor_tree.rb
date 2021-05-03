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
          @parent ||= superclass && AncestorTree.new(registry: registry, object: superclass)
        end

        # @return [Objects::NamespaceObject, nil]
        def superclass
          return @superclass if instance_variable_defined?(:@superclass)
          @superclass = begin
            if object.respond_to?(:base_class_address)
              base_class_superclass
            elsif object.respond_to?(:superclass_path)
              if object.superclass_path
                FindConstant.new(registry).find(object.superclass_path)
              else
                nil
              end
            else
              nil
            end
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

        # @return [Objects::NamespaceObject, nil]
        def base_class_superclass
          base_class = registry.get(object.base_class_address)
          if base_class && base_class.respond_to?(:superclass_path) && base_class.superclass_path
            FindMetaClass.new(registry).find(base_class.superclass_path)
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
