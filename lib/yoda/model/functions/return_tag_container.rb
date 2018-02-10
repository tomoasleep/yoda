module Yoda
  module Store
    module Functions
      module ReturnTagContainer

        private

        # @return [Types::Base]
        def return_type
          @return_type ||= parse_return_tag_type(return_tags.map(&:types).flatten)
        end

        # @param type_strings [Array<String>]
        # @return [Array<YARD::Tags::Tag>]
        def parse_return_tag_type(type_strings)
          (type_strings.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(type_strings)).change_root(namespace)
        end

        # @abstract
        # @return [Array<YARD::Tags::Tag>]
        def return_tags
          fail NotImplementedError
        end

        # @abstract
        # @return [YARD::CodeObjects::Base]
        def namespace
          fail NotImplementedError
        end
      end
    end
  end
end
