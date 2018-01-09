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
        code_object.copy_to(new_object)
        new_object
      end

      def register_class_object(code_object)
        new_parent = find_new_parent_of(code_object)
        new_object = YARD::CodeObjects::ClassObject.new(new_parent, code_object.name)
        code_object.copy_to(new_object)
        new_object
      end
    end
  end
end
