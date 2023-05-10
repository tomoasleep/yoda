require 'rbs'

module Yoda
  module Store
    class RbsImporter
      class Context
        
      end

      # @return [Objects::Patch]
      attr_reader :patch

      # @return [String, nil]
      attr_reader :root_path

      # @return [String, nil]
      attr_reader :source_path

      # @param id [String]
      # @param root_path [String, nil]
      # @param source_path [String, nil] if given overwrite the source path of objects.
      def initialize(id, root_path: nil, source_path: nil)
        @patch = Objects::Patch.new(id)
        @root_path = root_path
        @source_path = source_path
        @registered = Set.new
      end

      # @param declaration [RBS::AST::Declarations::t]
      def register(declaration)
        path = path_of(declaration)
        return if @registered.member?(path)
        @registered.add(path)
        register(declaration.parent) if declaration.parent

        new_objects = begin
          case declaration
          when RBS::AST::Declarations::Class
            process_class(declaration)
          when RBS::AST::Declarations::Module
            process_module(declaration)
          when RBS::AST::Declarations::Interface
            process_interface(declaration)
          when RBS::AST::Declarations::Constant
            process_constant(declaration)
          when RBS::AST::Declarations::Global
            process_global(declaration)
          when RBS::AST::Declarations::Alias
            process_alias(declaration)
          else
            fail ArgumentError, 'Unsupported type code object'
          end
        end

        [new_objects].flatten.compact.each { |new_object| patch.register(new_object) }
      end

      # @param declaration [RBS::AST::Declarations::Class]
      def process_class(declaration)
        object_class = Objects::ClassObject.new(
          path: path_to_store(declaration),
          document: declaration.comment.string,
          tag_list: declaration.tags.map { |tag| convert_tag(tag, '') } + code_object.docstring.ref_tags.map { |tag| convert_ref_tag(tag, '') },
          sources: declaration.files.map(&method(:convert_source)),
          primary_source: code_object[:current_file_has_comments] ? convert_source(code_object.files.first) : nil,
          instance_method_addresses: code_object.meths(included: false, scope: :instance).map { |meth| path_to_store(meth) },
          mixin_addresses: code_object.instance_mixins.map { |mixin| path_to_store(mixin) },
          constant_addresses: (code_object.children.select { |child| %i(constant module class).include?(child.type) }.map { |constant| constant.path } + ['Object']).uniq,
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

      # @param object [RBS::AST::Declarations::t]]
      # @return [String]
      def path_to_store(object)
        @paths_to_store ||= {}
        @paths_to_store[[object.type, object.path]] ||= path_of(object)
      end

      # @param declaration [RBS::AST::Declarations::t]
      # @return [String]
      def path_of(declaration)
        declaration.name.to_s
      end
    end
  end
end
