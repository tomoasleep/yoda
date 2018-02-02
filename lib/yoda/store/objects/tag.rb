module Yoda
  module Store
    module Objects
      class Tag
        # @return [String]
        attr_reader :tag_name

        # @return [String, nil]
        attr_reader :name, :text

        # @return [Array<String>]
        attr_reader :yard_types

        # @param tag_name   [String]
        # @param name       [String, nil]
        # @param yard_types [Array<String>]
        # @param text       [String, nil]
        def initialize(tag_name:, name: nil, yard_types: [], text: nil)
          @tag_name = tag_name
          @name = name
          @yard_types = yard_types
          @text = text
        end

        # @return [Hash]
        def to_hash
          { name: name, tag_name: tag_name, yard_types: yard_types, text: text }
        end
      end
    end
  end
end
