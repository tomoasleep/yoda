module Yoda
  module AST
    class CommentBlock
      # @abstract
      module RangeCalculation
        # @!method comment_block
        #   @abstract
        #   @return [CommentBlock]

        # @abstract
        # @return [Integer]
        def begin_index
          fail NotImplementedError
        end

        # @abstract
        # @return [Integer]
        def end_index
          fail NotImplementedError
        end

        # @return [Parsing::Location, nil]
        def begin_location
          @begin_location ||= comment_block.location_from_index(begin_index)
        end

        # @return [Parsing::Location, nil]
        def end_location
          @end_location ||= comment_block.location_from_index(end_index)
        end

        # @return [Parsing::Range, nil]
        def range
          if begin_location && end_location
            Parsing::Range.new(begin_location, end_location)
          else
            nil
          end
        end

        # @return [String, nil]
        def text
          if begin_location && end_location
            comment_block.text.slice(Range.new(begin_index, end_index))
          else
            nil
          end
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
