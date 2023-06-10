require 'rbs'

module Yoda
  module YARDExtensions
    class RbsExporter
      # @param file [String]
      # @return [RBS::AST::Declarations::Class]
      def self.convert(file)
        store = YARD::RegistryStore.new
        store.load(file)
        new.convert(store.root)
      end

      # @param file [String]
      # @return [String]
      def self.convert_to_string(file)
        store = YARD::RegistryStore.new
        store.load(file)

        new.convert_to_string(store.root)
      end

      # @param value [Array<RBS::AST::Declarations::Class>]
      # @return [String]
      def self.write_to_string(value)
        string = StringIO.new
        RBS::Writer.new(out: string).write([value])
        string.string
      end

      # @param root [Array<YARD::CodeObjects::NamespaceObject>]
      # @return [RBS::AST::Declarations::Class]
      def convert(root)
        convert_root_object(root)
      end

      # @param root [Array<YARD::CodeObjects::NamespaceObject>]
      # @return [String]
      def convert_to_string(root)
        self.class.write_to_string(convert(root))
      end

      private

      # @type (::YARD::CodeObjects::Base) -> (RBS::AST::Members::t | RBS::AST::Declarations::t | nil)
      def convert_member_object(code_object)
        case code_object.type
        when :class
          convert_class_object(code_object)
        when :module
          convert_module_object(code_object)
        when :method
          convert_method_object(code_object)
        when :constant
          convert_constant_object(code_object)
        else
          nil
        end
      end

      # @param code_object [::YARD::CodeObjects::ConstantObject]
      # @return [Objects::ValueObject]
      def convert_constant_object(code_object)
        RBS::AST::Declarations::Constant.new(
          name: code_object.name.to_sym,
          type: try_convert_to_type(code_object) || untyped,
          location: nil,
          comment: nil,
        )
      end

      # @param code_object [::YARD::CodeObjects::MethodObject]
      # @return [RBS::AST::Members::MethodDefinition]
      def convert_method_object(code_object)
        RBS::AST::Members::MethodDefinition.new(
          name: code_object.name.to_sym,
          kind: code_object.scope == :class ? :singleton : :instance,
          overload: false,
          comment: comment(code_object.docstring.to_s),
          visibility: code_object.visibility == :public ? :public : :private,
          location: nil,
          types: [convert_to_method_type(code_object)],
          annotations: [],
        )
      end

      # @type (::YARD::CodeObjects::NamespaceObject) -> RBS::AST::Members::t
      def convert_member_objects(code_object)
        source_members = code_object.tags(:rbs_signature).map { |tag| parse_rbs_signature(code_object, tag) }

        extends = code_object.class_mixins.map do |mod|
          RBS::AST::Members::Extend.new(
            name: type_name(path_to_store(mod)),
            args: [],
            location: nil,
            comment: nil,
            annotations: [],
          )
        end

        includes = code_object.instance_mixins.map do |mod|
          RBS::AST::Members::Include.new(
            name: type_name(path_to_store(mod)),
            args: [],
            location: nil,
            comment: nil,
            annotations: [],
          )
        end

        [
          *source_members,
          *extends,
          *includes,
          *code_object.children.map(&method(:convert_member_object)).compact,
        ]
      end

      # @param code_object [::YARD::CodeObjects::NamespaceObject]
      # @return [RBS::AST::Declarations::Class]
      def convert_root_object(code_object)
        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: :Object, namespace: RBS::Namespace.empty),
          super_class: nil,
          members: convert_member_objects(code_object),
          annotations: [],
          comment: nil,
          location: nil,
          type_params: [],
        )
      end

      # @param code_object [::YARD::CodeObjects::ModuleObject]
      # @return [RBS::AST::Declarations::Module]
      def convert_module_object(code_object)
        # TODO: Parse self @type
        RBS::AST::Declarations::Module.new(
          name: type_name(code_object.name),
          type_params: [],
          members: convert_member_objects(code_object),
          annotations: [],
          self_types: [],
          comment: comment(code_object.docstring.to_s),
          location: nil,
        )
      end

      # @param code_object [::YARD::CodeObjects::ClassObject]
      # @return [Array<Objects::ClassObject, Objects::MetaClassObject>]
      def convert_class_object(code_object)
        super_class =
          if code_object.superclass
            RBS::AST::Declarations::Class::Super.new(name: type_name(code_object.superclass.name), args: [], location: nil)
          else
            nil
          end

        # TODO: Parse self @type
        RBS::AST::Declarations::Class.new(
          name: type_name(code_object.name),
          type_params: [],
          super_class: super_class,
          members: convert_member_objects(code_object),
          annotations: [],
          comment: comment(code_object.docstring.to_s),
          location: nil,
        )
      end

      # @type (::YARD::CodeObjects::Base) -> RBS::Types::t
      def try_convert_to_type(code_object)
        type_tag = code_object.tags.find { |tag| tag.tag_name == 'type' }&.first
        return nil unless type_tag

        RBS::Parser.parse_type(type_tag.text)
      end

      # @type (::YARD::CodeObjects::MethodObject) -> RBS::MethodType
      def convert_to_method_type(code_object)
        type_tag = code_object.tags.find { |tag| tag.tag_name == 'type' }
        parsed_type = type_tag && try_parse_method_type_tag(type_tag)

        if parsed_type
          parsed_type
        else
          raw_parameters = convert_parameters(code_object)
          params = Model::FunctionSignatures::ParameterList.new(raw_parameters)

          # @type (Model::FunctionSignatures::Parameter) -> RBS::Types::t
          item_to_parameter = ->(item) do
            RBS::Types::Function::Param.new(type: untyped, name: item.name.to_sym)
          end

          function_type = RBS::Types::Function.new(
            required_positionals: params.required_parameters.map(&item_to_parameter),
            optional_positionals: params.optional_parameters.map(&item_to_parameter),
            rest_positionals: params.rest_parameter&.yield_self(&item_to_parameter),
            trailing_positionals: params.post_parameters.map(&item_to_parameter),
            required_keywords: params.required_keyword_parameters.map { |item| [item.name.to_sym, item_to_parameter.call(item)] }.to_h,
            optional_keywords: params.optional_keyword_parameters.map { |item| [item.name.to_sym, item_to_parameter.call(item)] }.to_h,
            rest_keywords: params.keyword_rest_parameter&.yield_self(&item_to_parameter),
            return_type: untyped,
          )

          RBS::MethodType.new(
            type_params: [],
            type: function_type,
            block: nil,
            location: nil,
          )
        end
      end

      # @type (::YARD::Tags::Tag) -> RBS::Types::t
      def try_parse_method_type_tag(type_tag)
        RBS::Parser.parse_method_type(type_tag.text)
      rescue RBS::ParsingError => e
        STDERR.puts "Failed to parse type: #{type_tag.text} (#{e.message})"
      end

      # @param object [::YARD::CodeObjects::MethodObject, ::YARD::Tags::OverloadTag]
      # @return [Array<(String, String)>]
      def convert_parameters(object)
        Model::YardSignatureParser.new(object.signature).to_a
      rescue Model::YardSignatureParser::ParseError => e
        # Cannot parse signature if the method is defined in C.
        Logger.trace "Failed to parse signature: #{object.signature}"
        object.parameters || []
      end

      # @type () -> RBS::Types::Bases::Any
      def untyped
        RBS::Types::Bases::Any.new(location: nil)
      end

      # @type (::YARD::CodeObjects::Base, ::YARD::Tags::Tag) -> RBS::AST::Members::t
      def parse_rbs_signature(code_object, tags)
        text =
          case code_object.type
          when :class
            <<~RBS
            class #{code_object.name}
              #{tag.text}
            end
            RBS
          when :module
            <<~RBS
            module #{code_object.name}
              #{tag.text}
            end
            RBS
          else
            fail "Unexpected code object type: #{code_object.type}"
          end

        RBS::Parser.parse_signature(text).first.members
      end

      def type_name(name)
        TypeName(name.to_s)
      end

      # @param code_object [::YARD::CodeObjects::Base]
      # @return [String]
      def path_to_store(object)
        @paths_to_store ||= {}
        @paths_to_store[[object.type, object.path]] ||= calc_path_to_store(object)
      end

      def comment(body)
        RBS::AST::Comment.new(string: body, location: nil)
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
