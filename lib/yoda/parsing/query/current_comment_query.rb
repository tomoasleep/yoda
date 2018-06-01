module Yoda
  module Parsing
    module Query
      # Provides helper methods to find the current comment which means the comment on the current position.
      class CurrentCommentQuery
        attr_reader :comments, :location

        # @param comments [Array<::Parser::Source::Comment>]
        # @param location [Location] represents the current position.
        def initialize(comments, location)
          fail ArgumentError, comments unless comments.all? { |comment| comment.is_a?(::Parser::Source::Comment) }
          fail ArgumentError, location unless location.is_a?(Location)
          @comments = comments
          @location = location
        end

        # The single line comment which the current position is on.
        # @return [::Parser::Source::Comment, nil]
        def current_comment
          @current_comment ||= comments.find { |comment| location.included?(comment.location) }
        end

        # The multiple line comments which the current position is on.
        # @return [Array<::Parser::Source::Comment>]
        def current_comment_block
          @current_comment_block ||= current_comment ? comment_blocks.find { |block| block.include?(current_comment) } : []
        end

        # The relative coordinates of the current position from the beginning position of the current comment.
        # @return [Location]
        def location_in_current_comment_block
          relative_position(location)
        end

        # @return [Location]
        def begin_point_of_current_comment_block
          Location.new(row: current_comment_block.first.location.line, column: current_comment_block.first.location.column)
        end

        # @group Coordinate conversion

        # Calculate relative position (the coordinates from the beginning point) from the relative position.
        # @param position [Location]
        def relative_position(position)
          position.move(row: 1 - current_comment_block.first.location.line, column: - current_comment_block.first.location.column)
        end

        # Calculate absolute position from the relative position.
        # @param position [Location]
        def absolute_position(position)
          position.move(row: current_comment_block.first.location.line - 1, column: current_comment_block.first.location.column)
        end

        # Calculate relative range from the relative range.
        # @param range [Range]
        def relative_range(range)
          range.move(row: 1 - current_comment_block.first.location.line, column: - current_comment_block.first.location.column)
        end

        # Calculate absolute range from the relative range.
        # @param range [Range]
        def absolute_range(range)
          range.move(row: current_comment_block.first.location.line - 1, column: current_comment_block.first.location.column)
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
