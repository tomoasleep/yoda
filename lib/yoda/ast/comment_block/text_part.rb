module Yoda
  module AST
    class CommentBlock
      class TextPart < BasePart
        # @return [CommentBlock]
        attr_reader :comment_block

        # @return [Parsing::CommentTokenizer::Text]
        attr_reader :token

        # @param comment_block [CommentBlock]
        # @param token [Parsing::CommentTokenizer::Text]
        def initialize(comment_block:, token:)
          @comment_block = comment_block
          @token = token
        end

        def begin_index
          token.content.offset
        end

        def end_index
          token.content.offset + token.content.length
        end
      end
    end
  end
end
