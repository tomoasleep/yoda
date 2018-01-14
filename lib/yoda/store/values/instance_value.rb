module Yoda
  module Store
    module Values
      class InstanceValue < Base
        attr_reader :registry, :class_object

        # @param registry [Registry]
        # @param class_object [::YARD::CodeObjects::ClassObject, ::YARD::CodeObjects::Proxy]
        def initialize(registry, class_object)
          fail ArgumentError, registry unless registry.is_a?(Registry)
          fail ArgumentError, class_object unless class_object.is_a?(::YARD::CodeObjects::NamespaceObject) || class_object.is_a?(::YARD::CodeObjects::Proxy)
          @registry = registry
          @class_object = class_object
        end

        # @return [Array<Function>]
        def methods
          return [] if class_object.type == :proxy
          class_object.meths(scope: :instance).map { |meth| Function.new(meth) } + object_methods
        end

        # @return [String]
        def path
          namespace.path
        end

        def namespace
          class_object
        end

        private

        def object_methods
          return [] if class_object.type == :proxy
          method_names = Set.new(class_object.meths(scope: :instance).map(&:name))
          if object = registry.find('::Object')
            object.meths(scope: :instance).reject { |o| method_names.include?(o.name) }.map { |meth| Function.new(meth) }
          else
            []
          end
        end
      end
    end
  end
end
