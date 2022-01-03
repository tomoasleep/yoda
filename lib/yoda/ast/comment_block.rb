module Yoda
  module AST
    class CommentBlock
      require 'yoda/ast/comment_block/base_part'
      require 'yoda/ast/comment_block/range_calculation'
      require 'yoda/ast/comment_block/tag_part'
      require 'yoda/ast/comment_block/tag_text_name_part'
      require 'yoda/ast/comment_block/tag_text_type_part'
      require 'yoda/ast/comment_block/text_part'
      require 'yoda/ast/comment_block/token'

      # @param comment_block [CommentBlock]
      # @param token [Parsing::CommentTokenizer::Sequence, Parsing::CommentTokenizer::Text]
      # @return [BasePart]
      def self.build_part(comment_block:, token:)
        case token
        when Parsing::CommentTokenizer::Sequence
          TagPart.new(comment_block: comment_block, token: token)
        when Parsing::CommentTokenizer::Text
          TextPart.new(comment_block: comment_block, token: token)
        else
          fail "unexpected"
        end
      end

      # @return [Array<::Parser::Source::Comment>]
      attr_reader :comments

      # @return [Vnode]
      attr_reader :node

      # @param comments [Array<::Parser::Source::Comment>]
      # @param node [Vnode]
      def initialize(comments, node: nil)
        @comments = Array(comments)
        @node = node
      end

      # @return [String]
      def text
        comments.map(&:text).join
      end

      # @return [Array<BasePart>]
      def parts
        @parts ||= parsed_tokens.map do |token|
          build_part(token)
        end
      end

      # @param location [Parsing::Location]
      # @return [BasePart, nil]
      def nearest_part(location)
        parts.find { |part| part.include?(location) }
      end

      # @param location [Parsing::Location]
      # @return [TagPart, nil]
      def nearest_tag_part(location)
        part = nearest_part(location)
        part&.is_a?(TagPart) ? part : nil
      end

      # @param index [Integer]
      # @return [Parsing::Location, nil]
      def location_from_index(index)
        partial_text = text.slice(::Range.new(0, index))
        *lines_before, curent_line = partial_text.split("\n", -1)
        begin_location&.move(row: lines_before.length, column: curent_line&.length || 0)
      end

      # @param location [Parsing::Location]
      # @return [Integer, nil]
      def offset_from_location(location)
        if begin_location
          row_diff = location.row - begin_location.row
          column_diff = location.column - begin_location.column

          lines = text.split("\n", -1)
          lines.slice(0, row_diff).join("\n").length + column_diff
        end
      end

      # @param token [Parsing::CommentTokenizer::Sequence, String]
      # @return [BasePart]
      def build_part(token)
        self.class.build_part(comment_block: self, token: token)
      end

      # @return [Parsing::Location, nil]
      def begin_location
        return nil unless Parsing::Location.valid_location?(comments.first.location)
        Parsing::Location.new(row: comments.first.location.line, column: comments.first.location.column)
      end

      # @return [Parsing::Location, nil]
      def end_location
        return nil unless Parsing::Location.valid_location?(comments.last.location)
        Parsing::Location.new(row: comments.last.location.last_line, column: comments.last.location.last_column)
      end

      # @return [Parsing::Range, nil]
      def range
        if begin_location && end_location
          Parsing::Range.new(begin_location, end_location)
        else
          nil
        end
      end

      private

      # @return [Array<String, Parsing::CommentTokenizer::Sequence>]
      def parsed_tokens
        @parsed_tokens ||= Parsing::CommentTokenizer.new.parse(text)
      end
    end
  end
end
