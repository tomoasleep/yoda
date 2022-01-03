module Yoda
  module AST
    class CommentBlock
      class TagTextTypePart < BasePart
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

        # @return [Array<Token>]
        def type_tokens
          @type_tokens ||= tokens.slice(1..-2).map { |token| Token.from_parslet(token, comment_block: comment_block) }
        end

        # @param location [Parsing::Location]
        # @return [Token, nil]
        def nearest_token(location)
          type_tokens.find { |token| token.include?(location) }
        end

        private

        def type_text
          text.slice(1..-2)
        end
      end
    end
  end
end
