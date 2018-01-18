module Yoda
  module Store
    module Values
      class ModuleValue < Base
        attr_reader :registry, :namespace_object

        # @param registry [Registry]
        # @param namespace_object [::YARD::CodeObjects::NamespaceObject, ::YARD::CodeObjects::Proxy]
        def initialize(registry, namespace_object)
          fail ArgumentError, registry unless registry.is_a?(Registry)
          fail ArgumentError, namespace_object unless namespace_object.is_a?(::YARD::CodeObjects::NamespaceObject) || namespace_object.is_a?(::YARD::CodeObjects::Proxy)
          @registry = registry
          @namespace_object = namespace_object
        end

        # @return [Array<Function>]
        def methods(visibility: nil)
          return [] if namespace_object.type == :proxy
          opts = { scope: :class, visibility: visibility }.compact
          namespace_object.meths(opts).map { |meth| Function.new(meth) } + parent_methods(visibility: visibility).reject { |ko| }
        end

        # @return [String]
        def path
          "#{namespace.path}.#{namespace.type == :class ? 'class' : 'module'}"
        end

        def namespace
          namespace_object
        end

        # @param [String]
        def docstring
          namespace.docstring
        end

        private

        def parent_methods(visibility: nil)
          case namespace_object.type
          when :class
            method_names = Set.new(namespace_object.meths(scope: :class).map(&:name))
            InstanceValue.new(registry, registry.find_or_proxy('::Class')).methods(visibility: visibility).reject { |m| method_names.include?(m.name) }
          when :module
            method_names = Set.new(namespace_object.meths(scope: :class).map(&:name))
            InstanceValue.new(registry, registry.find_or_proxy('::Module')).methods(visibility: visibility).reject { |m| method_names.include?(m.name) }
          else
            []
          end
        end
      end
    end
  end
end
