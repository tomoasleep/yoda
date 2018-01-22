module Yoda
  module Store
    class Function
      module TypeContainer
        # @param parameter_name [String]
        def type_of(parameter_name)
          tags = parameter_tags || []
          parse_type(tags.select { |tag| tag.name == parameter_name }.map(&:types).flatten)
        end

        def type_signature
          type.method_type_signature
        end

        private

        def calculate_type_tag_type
          nil unless type_tag
          parsed_type = type_tag.parsed_type
          parsed_type.is_a?(Types::FunctionType) ? parsed_type : Types::FunctionType.new(return_type: parsed_type)
        end

        def parse_type(type_strings)
          (type_strings.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(type_strings)).change_root(code_object.namespace)
        end
      end

      include TypeContainer
      attr_reader :code_object

      # @param code_object [YARD::CodeObjects::Base]
      def initialize(code_object)
        fail ArgumentError, code_object unless code_object.is_a?(YARD::CodeObjects::Base)
        @code_object = code_object
      end

      # @return [Types::FunctionType]
      def type
        @type ||= begin
          if type_tag
            calculate_type_tag_type
          elsif @code_object.tag(:overload)
            Signature.new(@code_object.tag(:overload)).type
          else
            params = parameters.map { |(name, default_value)| [name, type_of(name), default_value] }
            Types::FunctionType.new(return_type: return_type, parameters: params)
          end
        end
      end

      def type_tag
        @code_object.tag(:type)
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

        def type_tag
          overload_tag.tag(:type)
        end

        def code_object
          overload_tag.object
        end

        def return_type
          @return_type ||= parse_type(overload_tag.tags(:return).map(&:types).flatten)
        end

        def parameter_types
          tags = overload_tag.object.tags(:param) || []
          parameters.map do |name, default_value|
            [name, parse_type(tags.select { |tag| tag.name == name }.map(&:types).flatten)]
          end
        end

        # @return [Types::FunctionType]
        def type
          @type ||= begin
            if type_tag
              calculate_type_tag_type
            else
              params = parameters.map { |(name, default_value)| [name, type_of(name), default_value] }
              Types::FunctionType.new(return_type: return_type, parameters: params)
            end
          end
        end
      end
    end
  end
end
