require 'yoda/ast/comment_block/range_calculation'

module Yoda
  module AST
    class CommentBlock
      class Token
        # @param slice [Parslet::Slice]
        # @param comment_block [CommentBlock]
        # @return [CommentBlock::Slice]
        def self.from_parslet(slice, comment_block:)
          begin_location = comment_block.location_from_index(slice.offset)
          end_location = comment_block.location_from_index(slice.offset + slice.length)

          range = if begin_location && end_location
            Parsing::Range.new(begin_location, end_location)
          else
            nil
          end

          new(slice.to_s, range: range)
        end

        # @return [String]
        attr_reader :content

        # @return [Parsing::Range, nil]
        attr_reader :range

        # @param content [String]
        # @param range [Parsing::Range, nil]
        def initialize(content, range:)
          @content = content
          @range = range
        end

        # @param location [Parsing::Location]
        # @return [Boolean]
        def include?(location)
          range&.include?(location)
        end
      end
    end
  end
end
