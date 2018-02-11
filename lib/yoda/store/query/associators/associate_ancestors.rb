module Yoda
  module Store
    module Query
      module Associators
        class AssociateAncestors
          # @return [Registry]
          attr_reader :registry

          # @param registry [Registry]
          def initialize(registry)
            @registry = registry
          end

          # @param obj [Object::Base]
          def associate(obj)
            if obj.is_a?(Objects::NamespaceObject)
              obj.ancestors = Enumerator.new do |yielder|
                process(obj, yielder)
              end
            end
          end

          private

          # @param obj [Object::NamespaceObject]
          def process(scope, yielder)
            if scope.is_a?(Objects::NamespaceObject)
              yielder << scope
              associate_mixins(scope, yielder)

              if scope.is_a?(Objects::MetaClassObject)
                associate_metaclass_superclass(scope, yielder)
              elsif scope.is_a?(Objects::ClassObject)
                associate_superclass(scope, yielder)
              end
            end
          end

          # @param obj [Object::NamespaceObject]
          def associate_mixins(obj, yielder)
            obj.mixin_addresses.each do |address|
              if el = FindConstant.new(registry).find(address)
                yielder << el
              end
            end
          end

          # @param obj [Object::ClassObject]
          def associate_superclass(obj, yielder)
            super_class = FindConstant.new(registry).find(obj.superclass_address)
            if super_class
              process(super_class, yielder)
            end
          end

          # @param obj [Object::MetaClassObject]
          def associate_metaclass_superclass(obj, yielder)
            base_class = FindConstant.new(registry).find(obj.path)
            if base_class && meta_class = registry.find("#{base_class.superclass_address}%class")
              process(meta_class, yielder)
            end
          end
        end
      end
    end
  end
end
