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
                process(obj).each { |klass| yielder << klass }
              end
            end
          end

          private

          # @param scope [Object::NamespaceObject]
          # @return [Enumerator<Object::NamespaceObject>]
          def process(scope)
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

          # @param obj [Object::NamespaceObject]
          # @return [Enumerator<Object::NamespaceObject>]
          def find_mixins(obj)
            Enumerator.new do |yielder|
              obj.mixin_addresses.each do |address|
                if el = registry.find(address.to_s)
                  yielder << el
                end
              end
            end
          end

          # @param obj [Object::ClassObject]
          # @return [Enumerator<Object::NamespaceObject>]
          def find_superclass_ancestors(obj)
            if super_class = FindConstant.new(registry).find(obj.superclass_path)
              process(super_class)
            else
              []
            end
          end

          # @param obj [Object::MetaClassObject]
          # @return [Enumerator<Object::NamespaceObject>]
          def find_metaclass_superclass_ancestors(obj)
            base_class = registry.find(obj.base_class_address)
            if base_class && meta_class = FindMetaClass.new(registry).find(base_class.superclass_path || 'Object')
              process(meta_class)
            else
              []
            end
          end
        end
      end
    end
  end
end
