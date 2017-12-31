module Yoda
  module Store
    class Function
      attr_reader :code_object
      def initialize(code_object)
        @code_object = code_object
      end

      def parameter_types
        tags = @code_object.tags(:param)
        @code_object.parameters.map do |name, default_value|
          parse_type(tags.select { |tag| tag.name == name }.map(&:types).flatten)
        end
      end

      def return_type
        @return_type ||= parse_type(@code_object.tags(:name).map(&:types).flatten )
      end

      private

      def parse_type(type_strings)
        type_strings.empty? ? Types::AnyType.new : Types.parse_type_strings(type_strings)
      end
    end
  end
end
