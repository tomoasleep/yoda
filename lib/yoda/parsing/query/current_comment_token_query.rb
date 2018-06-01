module Yoda
  module Parsing
    module Query
      # Provides helper methods to find the current comment token (token on current position) and its kind.
      class CurrentCommentTokenQuery
        attr_reader :comment, :location_in_comment

        # @param comment [String]
        # @param location_in_comment [Location] represents relative coordinates of the current position from the beginning position of the current comment.
        def initialize(comment, location_in_comment)
          fail ArgumentError, comment unless comment.is_a?(String)
          fail ArgumentError, location_in_comment unless location_in_comment.is_a?(Location)
          @comment = comment
          @location_in_comment = location_in_comment
        end

        # @return [String]
        def current_line_comment
          comment.split("\n")[location_in_comment.row - 1] || ''
        end

        # @return [Symbol]
        def current_state
          return :none unless inputting_line
          inputting_line.current_state
        end

        # @return [String, nil]
        def current_word
          return nil unless inputting_line
          inputting_line.current_token.to_s
        end

        # @return [Range, nil]
        def current_range
          return nil if !inputting_line || !inputting_line.current_range
          start, last = inputting_line.current_range
          Range.new(Location.new(row: location_in_comment.row, column: start), Location.new(row: location_in_comment.row, column: last))
        end

        # @return [true, false]
        def at_sign?
          inputting_line.at_sign?
        end

        private

        # @return [CommentTokenizer::Sequence, nil]
        def tokenize
          return @tokenize if instance_variable_defined?(:@tokenized)
          @tokenize = CommentTokenizer.new.parse(line_to_current_position)
        rescue Parslet::ParseFailed
          @tokenize = nil
        end

        # @return [String]
        def line_to_current_position
          current_line_comment.slice(0...location_in_comment.column)
        end

        # @return [InputtingLine, nil]
        def inputting_line
          return nil unless tokenize
          @inputting_line ||= InputtingLine.new(tokenize, location_in_comment.column)
        end

        class InputtingLine
          # @type CommentTokenizer::Sequence
          attr_reader :token_sequence

          # @type Integer
          attr_reader :column

          # @param token_sequence [CommentTokenizer::Sequence]
          # @param column   [Integer]
          def initialize(token_sequence, column)
            @token_sequence = token_sequence
            @column = column
          end

          # @return [Parslet::Slice, nil]
          def tag
            token_sequence.tag
          end

          # @return [(Integer, Integer), nil]
          def current_range
            return nil unless current_token
            [current_token.offset, current_token.offset + current_token.size]
          end

          # @return [Parslet::Slice, nil]
          def current_token
            @current_token ||= token_sequence.all_tokens.find { |token| token.offset <= column && column <= token.offset + token.size }
          end

          # @return [Symbol]
          def current_state
            @current_state ||= begin
              if tag && %w(@type @!sig).include?(tag.to_s) && !on_tag?
                :type_tag_type
              elsif tag && token_sequence.parameter_tokens.empty?
                :tag
              elsif in_bracket?
                :type
              elsif at_parameter_name?
                :param
              else
                :none
              end
            end
          end

          # @return [true, false]
          def at_sign?
            current_token &&
            current_token.to_s.match?(/\A[{}.&\]\[\(\)<>]/) &&
            column == current_token.offset + current_token.size
          end

          private

          # @return [Boolean]
          def on_tag?
            tag && tag.offset <= column && column <= tag.offset + tag.size
          end

          # @return [Boolean]
          def at_parameter_name?
            case token_sequence.parameter_tokens.length
            when 0
              # TODO
              false
            when 1
              tag && %w(@param).include?(tag.to_s)
            else
              false
            end
          end

          # @return [Boolean]
          def in_bracket?
            token_sequence.parameter_tokens.reverse_each do |token|
              return false if token.to_s == ']'
              return true if token.to_s == '['
            end
            false
          end
        end
      end
    end
  end
end
