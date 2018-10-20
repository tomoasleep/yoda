require 'set'

module Yoda
  module Store
    module Query
      module Associators
        class AssociateAncestors
          class CircularReferenceError < StandardError
            # @param circular_scope [Objects::NamespaceObject, nil]
            def initialize(circular_scope)
              super("#{circular_scope&.path} appears twice")
            end
          end

          # @return [Registry]
          attr_reader :registry

          # @param registry [Registry]
          def initialize(registry)
            @registry = registry
          end

          # @param obj [Objects::Base]
          # @return [Enumerator<Objects::NamespaceObject>]
          def associate(obj)
            if obj.is_a?(Objects::NamespaceObject)
              Enumerator.new do |yielder|
                Processor.new(registry).process(obj).each { |klass| yielder << klass }
              end
            else
              []
            end
          end

          private

          class Processor
            # @return [Registry]
            attr_reader :registry

            # @param registry [Registry]
            def initialize(registry)
              @registry = registry
            end


            # @return [Set<Objects::Base>]
            def met
              @met ||= Set.new
            end

            # @param scope [Objects::NamespaceObject]
            # @return [Enumerator<Objects::NamespaceObject>]
            def process(scope)
              fail CircularReferenceError, scope if met.include?(scope)
              met.add(scope)

              Enumerator.new do |yielder|
                if scope.is_a?(Objects::NamespaceObject)
                  yielder << scope
                  find_mixins(scope).each { |mixin| yielder << mixin }

                  if scope.is_a?(Objects::MetaClassObject)
                    find_metaclass_superclass_ancestors(scope).each { |obj| yielder << obj }
                  elsif scope.is_a?(Objects::ClassObject)
                    find_superclass_ancestors(scope).each { |obj| yielder << obj }
                  end
                end
              end
            end

            # @param obj [Objects::NamespaceObject]
            # @return [Enumerator<Objects::NamespaceObject>]
            def find_mixins(obj)
              Enumerator.new do |yielder|
                obj.mixin_addresses.each do |address|
                  if el = registry.find(address.to_s)
                    yielder << el
                  end
                end
              end
            end

            # @param obj [Objects::ClassObject]
            # @return [Enumerator<Objects::NamespaceObject>]
            def find_superclass_ancestors(obj)
              if obj.superclass_path && super_class = FindConstant.new(registry).find(obj.superclass_path)
                process(super_class)
              else
                []
              end
            end

            # @param obj [Objects::MetaClassObject]
            # @return [Enumerator<Objects::NamespaceObject>]
            def find_metaclass_superclass_ancestors(obj)
              base_class = registry.find(obj.base_class_address)
              if base_class && base_class.is_a?(Objects::ClassObject) && base_class.superclass_path
                (meta_class = FindMetaClass.new(registry).find(base_class.superclass_path || 'Object')) ? process(meta_class) : []
              elsif base_class
                (class_object = registry.find('Class')) ? process(class_object) : []
              else
                []
              end
            end
          end
        end
      end
    end
  end
end
