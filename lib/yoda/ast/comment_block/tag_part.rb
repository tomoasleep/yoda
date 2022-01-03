module Yoda
  module AST
    class CommentBlock
      class TagPart < BasePart
        # @return [CommentBlock]
        attr_reader :comment_block

        # @return [Parsing::CommentTokenizer::Sequence]
        attr_reader :token

        # @param comment_block [CommentBlock]
        # @param token [Parsing::CommentTokenizer::Sequence]
        def initialize(comment_block:, token:)
          @comment_block = comment_block
          @token = token
        end

        # @return [Integer]
        def begin_index
          token.all_tokens.first.offset
        end

        # @return [Integer]
        def end_index
          last_token = token.all_tokens.last
          last_token.offset + last_token.length
        end

        # @return [TagTextTypePart, nil]
        def type_part
          return nil if tokens_in_bracket.empty?
          @type_part ||= begin
            TagTextTypePart.new(parent: self, tokens: tokens_in_bracket)
          end
        end

        # @return [TagTextNamePart, nil]
        def name_part
          @name_part ||= begin
            if tokens_before_bracket.empty?
              if tokens_after_bracket.empty?
                nil
              else
                TagTextNamePart.new(parent: self, tokens: [tokens_after_bracket.first])
              end
            else
              TagTextNamePart.new(parent: self, tokens: tokens_before_bracket)
            end
          end
        end

        # @param location [Parsing::Location]
        # @return [BasePart]
        def nearest_part(location)
          [type_part, name_part, self].compact.find { |part| part.range.include?(location) }
        end

        private

        # @return [Array<Parslet::Slice>]
        def tokens_in_bracket
          @tokens_in_bracket ||= begin
            tokens_from_bracket = token.all_tokens.drop_while { |token| token.to_s != "[" }
            tokens = tokens_from_bracket.slice_after { |token| token.to_s == "]" }.first

            tokens.last&.to_s == "]" ? tokens : []
          end
        end

        # @return [Array<Parslet::Slice>]
        def tokens_before_bracket
          @tokens_before_bracket ||= begin
            tokens = token.all_tokens.take_while { |token| token.to_s != "[" }
            tokens.length != token.all_tokens ? tokens : []
          end
        end

        # @return [Array<Parslet::Slice>]
        def tokens_after_bracket
          @tokens_after_bracket ||= begin
            tokens_after_left_bracket = token.all_tokens.drop_while { |token| token.to_s != "[" }.slice(1..)
            tokens_after_left_bracket.drop_while { |token| token.to_s != "]" }.slice(1..)
          end
        end
      end
    end
  end
end
