require 'yard'

module Yoda
  module Store
    class YardImporter
      attr_reader :store

      def self.import(file)
        new.tap { |importer| importer.load(file) }.import
      end

      def initialize
        @store = YARD::RegistryStore.new
        @registered = Set.new.add('')
      end

      # @param file [String]
      def load(file)
        store.load(file)
      end

      def import
        store.values.each do |el|
          register(el)
        end
      end

      # @fixme Use our own code objects instead of yard code objects.
      def register(code_object)
        return if @registered.member?(code_object.path)
        @registered.add(code_object.path)
        register(code_object.parent) unless code_object.parent.root?

        new_object =
          case code_object
          when YARD::CodeObjects::ClassObject
            register_class_object(code_object)
          when YARD::CodeObjects::ModuleObject
            register_module_object(code_object)
          when YARD::CodeObjects::ClassVariableObject
            register_class_variable_object(code_object)
          when YARD::CodeObjects::MethodObject
            register_method_object(code_object)
          when YARD::CodeObjects::MacroObject
            register_macro_object(code_object)
          when YARD::CodeObjects::ConstantObject
            register_constant_object(code_object)
          when YARD::CodeObjects::Proxy
            nil
          else
            fail ArgumentError, 'Unsupported type code object'
          end
      end

      private

      def find_new_parent_of(code_object)
        Registry.instance.find_or_proxy(code_object.parent.path)
      end

      def register_constant_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::ConstantObject.new(new_parent, code_object.name)
        code_object.copy_to(new_object)
        new_object
      end

      def register_macro_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::MacroObject.new(new_parent, code_object.name)
        code_object.copy_to(new_object)
        new_object
      end

      def register_method_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::MethodObject.new(new_parent, code_object.name, code_object.scope)
        code_object.copy_to(new_object)
        new_object
      end

      def register_class_variable_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::ClassVariableObject.new(new_parent, code_object.name)
        code_object.copy_to(new_object)
        new_object
      end

      def register_module_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::ModuleObject.new(new_parent, code_object.name)

        copy_namespace(code_object, new_object)
        new_object
      end

      def register_class_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::ClassObject.new(new_parent, code_object.name)

        copy_namespace(code_object, new_object)
        new_object
      end

      # @param origin_obj [::YARD::CodeObjects::NamespaceObject]
      # @param new_obj    [::YARD::CodeObjects::NamespaceObject]
      def copy_namespace(origin_obj, new_obj)
        new_obj.class_mixins += origin_obj.class_mixins
        new_obj.instance_mixins += origin_obj.instance_mixins
        new_obj.groups += origin_obj.groups
        new_obj.files += origin_obj.files
        new_obj.source_type = origin_obj.source_type
        new_obj.visibility = origin_obj.visibility
        new_obj.dynamic = new_obj.dynamic? || origin_obj.dynamic?

        new_obj.attributes = deep_merge(new_obj.attributes, transform_values_proxynize(origin_obj.attributes))
        new_obj.aliases = deep_merge(new_obj.aliases, transform_values_proxynize(origin_obj.aliases))

        new_obj.docstring = new_obj.base_docstring + origin_obj.base_docstring

        if new_obj.type == :class && new_obj.superclass && new_obj.superclass.type == :class && new_obj.superclass.name == :Object
          new_obj.superclass = proxynize(new_obj.superclass)
        end
      end

      # @param obj [::YARD::CodeObjects::Base, ::YARD::CodeObjects::Proxy]
      def proxynize(obj)
        return obj unless obj.type == :proxy
        YARD::CodeObjects::Proxy.new(:root, obj.path)
      end

      # @param hash [Hash]
      # @return [Hash]
      def transform_values_proxynize(hash)
        hash.transform_values do |value|
          if value.is_a?(Hash)
            transform_values_proxynize(value)
          elsif value.is_a?(YARD::CodeObjects::Base)
            proxynize(value)
          elsif value.is_a?(YARD::CodeObjects::Proxy)
            proxynize(value)
          else
            value
          end
        end
      end

      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |key, value1, value2|
          if value1.is_a?(Hash) && value2.is_a?(Hash)
            deep_merge(value1, value2)
          else
            value1
          end
        end
      end
    end
  end
end
