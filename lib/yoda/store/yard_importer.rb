require 'yard'

module Yoda
  module Store
    class YardImporter
      # @return [Objects::Patch]
      attr_reader :patch

      # @return [String, nil]
      attr_reader :root_path

      # @return [String, nil]
      attr_reader :source_path

      # @param file [String]
      # @param root_path [String, nil]
      # @return [Objects::Patch]
      def self.import(file, root_path: nil)
        store = YARD::RegistryStore.new
        store.load(file)
        root_path ||= File.expand_path('..', file)
        new(patch_id_for_file(file), root_path: root_path).import(store.values).patch
      end

      # @param file [String]
      # @return [String]
      def self.patch_id_for_file(file)
        file
      end

      # @param id [String]
      # @param root_path [String, nil]
      # @param source_path [String, nil] if given overwrite the source path of objects.
      def initialize(id, root_path: nil, source_path: nil)
        @patch = Objects::Patch.new(id)
        @root_path = root_path
        @source_path = source_path
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
        register(code_object.parent) if code_object.parent

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

        [new_objects].flatten.compact.each { |new_object| patch.register(new_object) }
      end

      private

      # @param code_object [::YARD::CodeObjects::NamespaceObject]
      # @return [Objects::ClassObject]
      def convert_root_object(code_object)
        object_class = Objects::ClassObject.new(
          path: path_to_store(code_object),
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, '') },
          ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, '') },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
          constant_addresses: (code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path } + ['Object']).uniq,
        )
        object_meta_class = Objects::MetaClassObject.new(
          path: path_to_store(code_object),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
        )
        [object_class, object_meta_class]
      end

      # @param code_object [::YARD::CodeObjects::ConstantObject]
      # @return [Objects::ValueObject]
      def convert_constant_object(code_object)
        Objects::ValueObject.new(
          path: path_to_store(code_object),
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, path_to_store(code_object.namespace)) },
          ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, path_to_store(code_object.namespace)) },
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
            tag_list: code_object.tags.map { |tag| convert_tag(tag, path_to_store(code_object.namespace)) },
            ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, path_to_store(code_object.namespace)) },
            overloads: code_object.tags(:overload).map { |tag| convert_overload_tag(tag, path_to_store(code_object.namespace)) },
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
            parameters: convert_parameters(code_object),
            visibility: :private,
          )
          object_object = Objects::ClassObject.new(
            path: 'Object',
            instance_method_addresses: ["Object#{code_object.sep}#{code_object.name}"],
          )
          [method_object, object_object]
        else
          Objects::MethodObject.new(
            path: path_to_store(code_object),
            document: code_object.docstring.to_s,
            tag_list: code_object.tags.map { |tag| convert_tag(tag, path_to_store(code_object.namespace)) },
            ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, path_to_store(code_object.namespace)) },
            overloads: code_object.tags(:overload).map { |tag| convert_overload_tag(tag, path_to_store(code_object.namespace)) },
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
            parameters: convert_parameters(code_object),
            visibility: code_object.visibility,
          )
        end
      end

      # @param code_object [::YARD::CodeObjects::ModuleObject]
      # @return [Array<Objects::ModuleObject, Objects::MetaClassObject>]
      def convert_module_object(code_object)
        module_object = Objects::ModuleObject.new(
          path: path_to_store(code_object),
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, path_to_store(code_object)) },
          ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, path_to_store(code_object)) },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: path_to_store(code_object),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
        )

        [module_object, meta_class_object]
      end

      # @param code_object [::YARD::CodeObjects::ClassObject]
      # @return [Array<Objects::ClassObject, Objects::MetaClassObject>]
      def convert_class_object(code_object)
        class_object = Objects::ClassObject.new(
          path: path_to_store(code_object),
          document: code_object.docstring.to_s,
          tag_list: code_object.tags.map { |tag| convert_tag(tag, path_to_store(code_object)) },
          ref_tag_list: code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, path_to_store(code_object)) },
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
          constant_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| path_to_store(constant) },
          superclass_path: !code_object.superclass || code_object.superclass&.path == 'Qnil' ? nil : path_to_store(code_object.superclass),
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: path_to_store(code_object),
          sources: code_object.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :class).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.class_mixins.map { |mixin| path_to_store(mixin) },
        )

        [class_object, meta_class_object]
      end

      # @param tag [::YARD::Tags::Tag]
      # @param namespace [String]
      # @return [Objects::Tag]
      def convert_tag(tag, namespace)
        case tag
        when YARD::Tags::OptionTag
          Objects::Tag.new(
            tag_name: tag.tag_name,
            name: tag.name,
            yard_types: tag.pair.types,
            text: tag.pair.text,
            lexical_scope: convert_to_lexical_scope(namespace),
            option_key: tag.pair.name,
            option_default: tag.pair.defaults,
          )
        else
          Objects::Tag.new(
            tag_name: tag.tag_name,
            name: tag.name,
            yard_types: tag.types,
            text: tag.text,
            lexical_scope: convert_to_lexical_scope(namespace),
          )
        end
      end

      # @param tag [::YARD::Tags::RefTagList]
      # @param namespace [String]
      # @return [Objects::ReferenceTag]
      def convert_ref_tag(tag, namespace)
        Objects::ReferenceTag.new(
          tag_name: tag.tag_name,
          name: tag.name,
          reference_path: tag.owner.path,
          lexical_scope: convert_to_lexical_scope(namespace),
        )
      end

      # @param object [::YARD::CodeObjects::MethodObject, ::YARD::Tags::OverloadTag]
      # @return [Array<(String, String)>]
      def convert_parameters(object)
        Model::YardSignatureParser.new(object.signature).to_a
      rescue Model::YardSignatureParser::ParseError => e
        Logger.warn "Failed to parse signature: #{object.signature}"
        object.parameters || []
      end

      # @param tag [::YARD::Tags::OverloadTag]
      # @param namespace [String]
      # @return [Objects::Tag]
      def convert_overload_tag(tag, namespace)
        Objects::Overload.new(name: tag.name.to_s, tag_list: tag.tags.map { |tag| convert_tag(tag, namespace) }, document: tag.docstring.to_s, parameters: convert_parameters(tag))
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
          path: path_to_store(code_object),
          document: '',
          tag_list: [],
          ref_tag_list: [],
          sources: [],
          primary_source: nil,
          instance_method_addresses: [],
          mixin_addresses: [],
          constant_addresses: [],
        )

        meta_class_object = Objects::MetaClassObject.new(
          path: path_to_store(code_object),
          sources: [],
          primary_source: nil,
          instance_method_addresses: [],
          mixin_addresses: [],
        )

        [module_object, meta_class_object]
      end

      # @param source [(String, Integer)]
      # @return [(String, Integer, Integer)]
      def convert_source(source)
        file, line = source
        file = source_path if source_path && file == "(stdin)"
        [root_path ? File.expand_path(file, root_path) : file, line, 0]
      end

      # @param code_object [::YARD::CodeObjects::Base]
      # @return [String]
      def path_to_store(object)
        @paths_to_store ||= {}
        @paths_to_store[[object.type, object.path]] ||= calc_path_to_store(object)
      end

      # @param code_object [::YARD::CodeObjects::Base]
      # @return [String] absolute object path to store.
      def calc_path_to_store(object)
        return 'Object' if object.root?
        parent_path = path_to_store(object.parent)

        if object.type == :proxy || object.is_a?(YARD::CodeObjects::Proxy)
          # For now, we suppose the proxy object exists directly under its namespace.
          [path_to_store(object.parent), object.name].join('::')
        elsif object.parent.path == path_to_store(object.parent)
          object.path
        else
          [path_to_store(object.parent), object.name].join(object.sep)
        end.gsub(/^Object::/, '')
      end
    end
  end
end
