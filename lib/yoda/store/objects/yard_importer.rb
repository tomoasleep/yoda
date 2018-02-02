require 'yard'

module Yoda
  module Store
    module Objects
      class YardImporter
        # @return [Patch]
        attr_reader :patch

        # @return [::YARD::RegistryStore]
        attr_reader :store

        # @return [String]
        attr_reader :yard_file

        # @param file [String]
        def self.import(file)
          new(file).tap { |importer| importer }.import
        end

        # @param yard_file [String]
        def initialize(yard_file)
          @yard_file = yard_file
          @store = YARD::RegistryStore.new
          @patch = Patch.new(yard_file)
          @registered = Set.new
        end

        # @return [String]
        def project_root
          @project_root ||= File.expand_path('..', yard_file)
        end

        # @return [self]
        def import
          store.load(yard_file)
          store.values.each do |el|
            register(el)
          end
          self
        end

        # @fixme Use our own code objects instead of yard code objects.
        def register(code_object)
          return if @registered.member?(code_object.path)
          @registered.add(code_object.path)
          register(code_object.parent) if code_object.parent && !code_object.parent.root?

          new_objects =
            case code_object
            when YARD::CodeObjects::ClassObject
              convert_class_object(code_object)
            when YARD::CodeObjects::ModuleObject
              convert_module_object(code_object)
            when YARD::CodeObjects::ClassVariableObject
              # convert_class_variable_object(code_object)
            when YARD::CodeObjects::MethodObject
              convert_method_object(code_object)
            when YARD::CodeObjects::MacroObject
              # convert_macro_object(code_object)
            when YARD::CodeObjects::ConstantObject
              convert_constant_object(code_object)
            when YARD::CodeObjects::Proxy
              nil
            else
              fail ArgumentError, 'Unsupported type code object'
            end

          [new_objects].flatten.compact.each { |new_object| patch.register(new_object) }
        end

        private

        # @param code_object [::YARD::CodeObjects::ConstantObject]
        # @return [ConstantObject]
        def convert_constant_object(code_object)
          ValueObject.new(
            code_object.path,
            document: code_object.docstring,
            tag_list: code_object.tags.map(&method(:convert_tag)),
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            value: code_object.value,
          )
        end

        # @param code_object [::YARD::CodeObjects::MethodObject]
        # @return [MethodObject]
        def convert_method_object(code_object)
          MethodObject.new(
            path: code_object.path,
            document: code_object.docstring,
            tag_list: code_object.tags.map(&method(:convert_tag)),
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            parameters: code_object.parameters,
            visibility: code_object.visibility,
          )
        end

        # @param code_object [::YARD::CodeObjects::ModuleObject]
        # @return [Array<ModuleObject, MetaClassObject>]
        def convert_module_object(code_object)
          module_object = ModuleObject.new(
            path: code_object.path,
            document: code_object.docstring,
            tag_list: code_object.tags.map(&method(:convert_tag)),
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            instance_method_paths: code_object.meths(included: false, scope: :instance).map(&:path),
            instance_mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
            child_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
          )

          meta_class_object = MetaClassObject.new(
            path: code_object.path,
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            instance_method_paths: code_object.meths(included: false, scope: :class).map(&:path),
            instance_mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
          )

          [module_object, meta_class_object]
        end

        # @param code_object [::YARD::CodeObjects::ClassObject]
        # @return [Array<ClassObject, MetaClassObject>]
        def convert_class_object(code_object)
          class_object = ClassObject.new(
            path: code_object.path,
            document: code_object.docstring,
            tag_list: code_object.tags.map(&method(:convert_tag)),
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            instance_method_paths: code_object.meths(included: false, scope: :instance).map(&:path),
            instance_mixin_addresses: code_object.instance_mixins.map { |mixin| mixin.path },
            child_addresses: code_object.children.select{ |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path },
            superclass: code_object.superclass.path,
          )

          meta_class_object = MetaClassObject.new(
            path: code_object.path,
            sources: code_object.files.map(&method(:convert_source)),
            primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.file) : nil,
            instance_method_paths: code_object.meths(included: false, scope: :class).map(&:path),
            instance_mixin_addresses: code_object.class_mixins.map { |mixin| mixin.path },
          )

          [class_object, meta_class_object]
        end

        # @param tag [::YARD::Tags::Tag]
        # @return [Tag]
        def convert_tag(tag)
          Tag.new(tag_name: tag.tag_name, name: tag.name, yard_types: tag.types, text: tag.text)
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
          [File.expand_path(file, project_root), line, 0]
        end
      end
    end
  end
end
