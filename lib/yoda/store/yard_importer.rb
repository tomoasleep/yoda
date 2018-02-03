require 'yard'

module Yoda
  module Store
    class YardImporter
      # @return [Objects::Patch]
      attr_reader :patch

      # @return [String, nil]
      attr_reader :root_path

      # @param file [String]
      # @return [Objects::Patch]
      def self.import(file)
        store = YARD::RegistryStore.new
        store.load(file)
        root_path = File.expand_path('..', file)
        new(file, root_path: root_path).import(store.values).patch
      end

      # @param id [String]
      def initialize(id, root_path: nil)
        @patch = Objects::Patch.new(id)
        @root_path = root_path
        @registered = Set.new
      end

      # @param values [Array<YARD::CodeObjects::Base>]
      # @return [self]
      def import(values)
        values.each do |el|
          register(el)
        end
        self
      end

      # @param code_object [YARD::CodeObjects::Base]
      def register(code_object)
        return if @registered.member?(code_object.path)
        @registered.add(code_object.path)
        register(code_object.parent) if code_object.parent && !code_object.parent.root?

        new_objects = begin
          case code_object.type
          when :root
            convert_root_object(code_object)
          when :class
            convert_class_object(code_object)
          when :module
            convert_module_object(code_object)
          when :classvariable
            # convert_class_variable_object(code_object)
          when :method
            convert_method_object(code_object)
          when :macro
            # convert_macro_object(code_object)
          when :constant
            convert_constant_object(code_object)
          when :proxy
            nil
          else
            fail ArgumentError, 'Unsupported type code object'
          end
        end

        [new_objects].flatten.compact.each { |new_object| patch.register(new_object) }
      end

      private

      # @param code_object [::YARD::CodeObjects::NamespaceObject]
      # @return [Objects::ClassObject]
      def convert_root_object(code_object)
        # @todo Add meta class for main object.
        Objects::ClassObject.new(
          path: 'Object',
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map(&method(:convert_tag)),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
        )
      end

      # @param code_object [::YARD::CodeObjects::ConstantObject]
      # @return [Objects::ValueObject]
      def convert_constant_object(code_object)
        Objects::ValueObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map(&method(:convert_tag)),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          value: code_object.value,
        )
      end

      # @param code_object [::YARD::CodeObjects::MethodObject]
      # @return [Objects::MethodObject]
      def convert_method_object(code_object)
        Objects::MethodObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map(&method(:convert_tag)),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          parameters: code_object.parameters,
          visibility: code_object.visibility,
        )
      end

      # @param code_object [::YARD::CodeObjects::ModuleObject]
      # @return [Array<Objects::ModuleObject, Objects::MetaClassObject>]
      def convert_module_object(code_object)
        module_object = Objects::ModuleObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map(&method(:convert_tag)),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: code_object.path,
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
        )

        [module_object, meta_class_object]
      end

      # @param code_object [::YARD::CodeObjects::ClassObject]
      # @return [Array<Objects::ClassObject, Objects::MetaClassObject>]
      def convert_class_object(code_object)
        class_object = Objects::ClassObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map(&method(:convert_tag)),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
          superclass_address: code_object.superclass&.path,
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: code_object.path,
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map(&:path),
          mixin_addresses: code_object.class_mixins.map { |mixin| mixin.path },
        )

        [class_object, meta_class_object]
      end

      # @param tag [::YARD::Tags::Tag]
      # @return [Objects::Tag]
      def convert_tag(tag)
        Objects::Tag.new(tag_name: tag.tag_name, name: tag.name, yard_types: tag.types, text: tag.text)
      end

      # @param symbol [Symbol]
      # @return [Symbol]
      def convert_yard_object_type(type)
        case type
        when :constant
          :value
        else
          type
        end
      end

      # @param source [(String, Integer)]
      # @return [(String, Integer, Integer)]
      def convert_source(source)
        file, line = source
        [root_path ? File.expand_path(file, root_path) : nil, line, 0]
      end
    end
  end
end
