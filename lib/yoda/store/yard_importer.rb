require 'yard'

module Yoda
  module Store
    class YardImporter
      # @return [Objects::Patch]
      attr_reader :patch

      # @return [String, nil]
      attr_reader :root_path

      # @param file [String]
      # @param root_path [String, nil]
      # @return [Objects::Patch]
      def self.import(file, root_path: nil)
        store = YARD::RegistryStore.new
        store.load(file)
        root_path ||= File.expand_path('..', file)
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
            create_proxy_module(code_object)
          else
            fail ArgumentError, 'Unsupported type code object'
          end
        end

        register_to_parent_proxy(code_object) if code_object.parent && code_object.parent.type == :proxy
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
          tag_list: code_object.tags.map { |tag| convert_tag(tag, '') },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: (code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path } + ['Object']).uniq,
        )
      end

      # @param code_object [::YARD::CodeObjects::ConstantObject]
      # @return [Objects::ValueObject]
      def convert_constant_object(code_object)
        Objects::ValueObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, code_object.namespace.path) },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          value: code_object.value,
        )
      end

      # @param code_object [::YARD::CodeObjects::MethodObject]
      # @return [Objects::MethodObject, (Objects::MethodObject, Object::ClassObject)]
      def convert_method_object(code_object)
        if code_object.namespace.root?
          # @todo Remove root oriented method path from Object namespace
          method_object = Objects::MethodObject.new(
            path: "Object#{code_object.sep}#{code_object.name}",
            document: code_object.docstring.to_s,
            tag_list: code_object.tags.map { |tag| convert_tag(tag, code_object.namespace.path) },
            overloads: code_object.tags(:overload).map { |tag| convert_overload_tag(tag, code_object.namespace.path) },
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
            parameters: code_object.parameters,
            visibility: :private,
          )
          object_object = Objects::ClassObject.new(
            path: 'Object',
            instance_method_addresses: ["Object#{code_object.sep}#{code_object.name}"],
          )
          [method_object, object_object]
        else
          Objects::MethodObject.new(
            path: code_object.path,
            document: code_object.docstring.to_s,
            tag_list: code_object.tags.map { |tag| convert_tag(tag, code_object.namespace.path) },
            overloads: code_object.tags(:overload).map { |tag| convert_overload_tag(tag, code_object.namespace.path) },
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
            parameters: code_object.parameters,
            visibility: code_object.visibility,
          )
        end
      end

      # @param code_object [::YARD::CodeObjects::ModuleObject]
      # @return [Array<Objects::ModuleObject, Objects::MetaClassObject>]
      def convert_module_object(code_object)
        module_object = Objects::ModuleObject.new(
          path: code_object.path,
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, code_object.path) },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: code_object.path,
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
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
          tag_list: code_object.tags.map { |tag| convert_tag(tag, code_object.path) },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map(&:path),
          mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
          superclass_path: code_object.superclass&.path == 'Qnil' ? nil : code_object.superclass&.path,
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: code_object.path,
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map(&:path),
          mixin_addresses: code_object.class_mixins.map { |mixin| mixin.path },
        )

        [class_object, meta_class_object]
      end

      # @param tag [::YARD::Tags::Tag]
      # @param namespace [String]
      # @return [Objects::Tag]
      def convert_tag(tag, namespace)
        Objects::Tag.new(tag_name: tag.tag_name, name: tag.name, yard_types: tag.types, text: tag.text, lexical_scope: convert_to_lexical_scope(namespace))
      end

      # @param tag [::YARD::Tags::OverloadTag]
      # @param namespace [String]
      # @return [Objects::Tag]
      def convert_overload_tag(tag, namespace)
        Objects::Overload.new(name: tag.name.to_s, tag_list: tag.tags.map { |tag| convert_tag(tag, namespace) }, document: tag.docstring.to_s, parameters: tag.parameters)
      end

      # @param namespace [String]
      # @return [Array<String>]
      def convert_to_lexical_scope(namespace)
        path = Model::Path.new(namespace)
        ((path.to_s.empty? ? [] : [path]) + path.parent_paths).map(&:to_s)
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

      # @param code_object [::YARD::CodeObjects::Proxy]
      # @return [Array<Objects::ModuleObject>]
      def create_proxy_module(code_object)
        module_object = Objects::ModuleObject.new(
          path: code_object.path,
          document: '',
          tag_list: [],
          sources: [],
          primary_source: nil,
          instance_method_addresses: [],
          mixin_addresses: [],
          constant_addresses: [],
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: code_object.path,
          sources: [],
          primary_source: nil,
          instance_method_addresses: [],
          mixin_addresses: [],
        )

        [module_object, meta_class_object]
      end

      # @param code_object [::YARD::CodeObjects::Base]
      # @return [vaid]
      def register_to_parent_proxy(code_object)
        proxy_module = patch.find(code_object.parent.path)
        proxy_module.instance_method_addresses.push(code_object.path) if code_object.type == :method
        proxy_module.constant_addresses.push(code_object.path) if [:class, :module, :proxy].include?(code_object.type)
      end

      # @param source [(String, Integer)]
      # @return [(String, Integer, Integer)]
      def convert_source(source)
        file, line = source
        [root_path ? File.expand_path(file, root_path) : file, line, 0]
      end
    end
  end
end
