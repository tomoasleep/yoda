module Yoda
  module Store
    module Functions
      module TypeTagContainer

        private

        # @return [Array<Types::FunctionType>]
        def type_tag_types
          @type_tag_types ||= type_tags.map { |type_tag| parse_type_tag(type_tag) }
        end

        # @param type_tag [YARDExtensions::TypeTag]
        # @return [Types::FunctionType]
        def parse_type_tag(type_tag)
          parsed_type = type_tag.parsed_type
          parsed_type.is_a?(Types::FunctionType) ? parsed_type : Types::FunctionType.new(return_type: parsed_type)
        end

        # @abstract
        # @return [Array<(String, String)>]
        def type_tags
          fail NotImplementedError
        end
      end
    end
  end
end
