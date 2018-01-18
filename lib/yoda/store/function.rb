module Yoda
  module Store
    class Function
      module TypeContainer
        # @return [Types::FunctionType]
        def type
          @type ||= begin
            params = parameters.map { |(name, default_value)| [name, type_of(name), default_value] }
            Types::FunctionType.new(return_type: return_type, parameters: params)
          end
        end

        # @param parameter_name [String]
        def type_of(parameter_name)
          tags = parameter_tags || []
          parse_type(tags.select { |tag| tag.name == parameter_name }.map(&:types).flatten)
        end

        def type_signature
          type.method_type_signature
        end

        private

        def parse_type(type_strings)
          (type_strings.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(type_strings)).change_root(@code_object.namespace)
        end
      end

      include TypeContainer
      attr_reader :code_object

      # @param code_object [YARD::CodeObjects::Base]
      def initialize(code_object)
        fail ArgumentError, code_object unless code_object.is_a?(YARD::CodeObjects::Base)
        @code_object = code_object
      end

      def parameter_types
        @code_object.parameters.map do |name, default_value|
          [name, type_of(name)]
        end
      end

      # @return [String]
      def name_with_namespace
        @code_object.namespace.name.to_s + @code_object.sep + name.to_s
      end

      # @return [Symbol]
      def name
        @code_object.name
      end

      # @return [String]
      def signature
        @code_object.signature
      end

      # @return [String]
      def docstring
        @code_object.docstring
      end

      # @return [Array<(String, String)>]
      def parameters
        @code_object.parameters
      end

      # @return [Array<String>]
      def parameter_names
        parameters.map(&:first)
      end

      def return_type
        @return_type ||= parse_type(@code_object.tags(:return).map(&:types).flatten)
      end

      def signatures
        @code_object.tags(:overload).map { |tag| Signature.new(tag) }
      end

      def parameter_tags
        @code_object.tags(:param)
      end

      class Signature
        include TypeContainer

        # @!attribute [r] overload_tag
        #   @return [::YARD::Tags::OverloadTag]
        attr_reader :overload_tag

        # @param overload_tag [YARD::Tags::OverloadTag]
        def initialize(overload_tag)
          @overload_tag = overload_tag
        end

        # @return [Symbol]
        def name
          overload_tag.name
        end

        # @return [String]
        def signature
          overload_tag.signature
        end

        # @return [String]
        def docstring
          overload_tag.docstring
        end

        # @return [Array<(String, String)>]
        def parameters
          overload_tag.parameters
        end

        # @return [Array<String>]
        def parameter_names
          parameters.map(&:first)
        end

        def parameter_tags
          overload_tag.tags(:param)
        end

        def return_type
          @return_type ||= parse_type(@code_object.tags(:return).map(&:types).flatten)
        end

        def parameter_types
          tags = overload_tag.object.tags(:param) || []
          parameters.map do |name, default_value|
            [name, parse_type(tags.select { |tag| tag.name == name }.map(&:types).flatten)]
          end
        end
      end
    end
  end
end
