module Yoda
  module YARDExtensions
    class TypeTag < YARD::Tags::Tag
      def parsed_type
        return @parsed_type if instance_variable_defined?('@parsed_type')
        @parsed_type = Parsing::TypeParser.new.safe_parse(text)
      end
    end
  end
end
