module Yoda
  module Model
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

        # @return [Array<Functions::Base>]
        def methods(visibility: nil)
          return [] if namespace_object.type == :proxy
          @methods ||= begin
            opts = { scope: :class, visibility: visibility }.compact
            class_methods = namespace_object.meths(opts).map { |meth| Functions::Method.new(meth) } + constructors
            class_method_names = Set.new(class_methods.map(&:name))
            parent_meths = parent_methods(visibility: visibility).reject { |m| class_method_names.include?(m.name) }
            class_methods + parent_meths
          end
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

        # @return [Array<[String, Integer]>]
        def defined_files
          namespace.files
        end

        private

        # @return [Array<Functions::Constructor>]
        def constructors
          [] unless namespace_object.type == :class
          [] if namespace.child(name: :new, scope: :class)
          [namespace.child(name: :initialize, scope: :instance)].map do |method_object|
            Functions::Constructor.new(method_object)
          end
        end

        # @return [Array<Functions::Base>]
        def parent_methods(visibility: nil)
          case namespace_object.type
          when :class
            InstanceValue.new(registry, registry.get_or_proxy('::Class')).methods(visibility: visibility)
          when :module
            InstanceValue.new(registry, registry.get_or_proxy('::Module')).methods(visibility: visibility)
          else
            []
          end
        end
      end
    end
  end
end
