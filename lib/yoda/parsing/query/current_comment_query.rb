module Yoda
  module Parsing
    module Query
      class CurrentCommentQuery
        attr_reader :comments, :location

        # @param comments [Array<::Parser::Source::Comment>]
        # @param location [Location]
        def initialize(comments, location)
          fail ArgumentError, comments unless comments.all? { |comment| comment.is_a?(::Parser::Source::Comment) }
          fail ArgumentError, location unless location.is_a?(Location)
          @comments = comments
          @location = location
        end

        # @return [::Parser::Source::Comment, nil]
        def current_comment
          @current_comment ||= comments.find { |comment| location.included?(comment.location) }
        end

        # @return [Array<::Parser::Source::Comment>]
        def current_comment_block
          @current_comment_block ||= current_comment ? comment_blocks.find { |block| block.include?(current_comment) } : []
        end

        # @return [Location]
        def location_in_current_comment_block
          location.move(row: 1 - current_comment_block.first.location.line, column: - current_comment_block.first.location.column)
        end

        # @return [Location]
        def begin_point_of_current_comment_block
          Location.new(row: current_comment_block.first.location.line, column: current_comment_block.first.location.column)
        end

        # @return [String]
        def current_comment_block_text
          current_comment_block.map(&:text).join("\n")
        end

        private

        # @return [Array<Array<::Parser::Source::Comment>>]
        def comment_blocks
          @comment_blocks ||= comments.chunk_while { |i, j| i.location.line + 1 == j.location.line }
        end
      end
    end
  end
end
