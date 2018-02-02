module Yoda
  module Store
    module Objects
      class TagList
        # @return [String]
        attr_reader :path

        # @return [Array<Tags>]
        attr_reader :tags

        # @param path [String]
        # @param tags [Array<Tag>]
        def initialize(path, tags)
          @path = path
          @tags = tags
        end

        # @return [Hash]
        def to_hash
          { path: path, tags: tags.map(&:to_hash) }
        end

        # @return [Symbol]
        def type
          :tag_list
        end

        # @return [String]
        def address
          "#{type}:#{path}"
        end
      end
    end
  end
end
