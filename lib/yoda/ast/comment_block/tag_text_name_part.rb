module Yoda
  module AST
    class CommentBlock
      # The name part of the tag's text.
      #
      # @example
      #   @param var_name [Type] description
      #          ~~~~~~~~
      #          ^ here
      #
      class TagTextNamePart < BasePart
        # @return [BasePart]
        attr_reader :parent

        # @return [Array<Parslet::Slice>]
        attr_reader :tokens

        # @param parent [BasePart]
        # @param tokens [Array<Parslet::Slice>]
        def initialize(parent:, tokens:)
          @parent = parent
          @tokens = tokens
        end

        # @return [CommentBlock]
        def comment_block
          parent.comment_block
        end

        # @return [Integer]
        def begin_index
          tokens.first.offset
        end

        # @return [Integer]
        def end_index
          tokens.last.offset + tokens.last.length
        end

        # @return [String]
        def to_s
          Token.join(tokens)
        end
      end
    end
  end
end
