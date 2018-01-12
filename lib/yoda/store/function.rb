module Yoda
  module Store
    class Function
      attr_reader :code_object

      # @param code_object [YARD::CodeObjects::Base]
      def initialize(code_object)
        fail ArgumentError, code_object unless code_object.is_a?(YARD::CodeObjects::Base)
        @code_object = code_object
      end

      def parameter_types
        tags = @code_object.tags(:param) || []
        @code_object.parameters.map do |name, default_value|
          [name, parse_type(tags.select { |tag| tag.name == name }.map(&:types).flatten)]
        end
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

      private

      def parse_type(type_strings)
        (type_strings.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(type_strings)).change_root(@code_object.namespace)
      end

      class Signature
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
