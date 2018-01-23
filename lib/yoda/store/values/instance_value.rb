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

        # @return [Array<Functions::Base>]
        def methods(visibility: nil)
          return [] if class_object.type == :proxy
          opts = { scope: :instance, visibility: visibility }.compact
          class_object.meths(opts).map { |meth| Functions::Method.new(meth) } + object_methods(visibility: visibility)
        end

        # @return [String]
        def path
          namespace.path
        end

        def namespace
          class_object
        end

        # @param [String]
        def docstring
          class_object.docstring
        end

        private

        # @return [Array<Functions::Base>]
        def object_methods(visibility: nil)
          return [] if class_object.type == :proxy
          opts = { scope: :instance, visibility: visibility }.compact
          method_names = Set.new(class_object.meths(opts).map(&:name))
          if object = registry.find('::Object')
            object.meths(opts)
              .reject { |o| ![visibility].flatten.include?(:private) && o.namespace.name == :Kernel }
              .reject { |o| method_names.include?(o.name) }
              .map { |meth| Functions::Method.new(meth) }
          else
            []
          end
        end
      end
    end
  end
end
