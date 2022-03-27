module Yoda
  module Model
    module Descriptions
      # @abstract
      class RequirePathDescription
        # @return [String]
        attr_reader :path

        # @param path [String]
        def initialize(path)
          @path = path
        end

        # @abstract
        # @return [String]
        def title
          path
        end

        # @abstract
        # @return [String]
        def sort_text
          path
        end

        # @return [String]
        def label
          sort_text
        end

        # @abstract
        # @return [String]
        def to_markdown
          path
        end

        # Return an LSP MarkedString content for description
        # @return [String, Hash]
        def markup_content
          to_markdown
        end
      end
    end
  end
end
