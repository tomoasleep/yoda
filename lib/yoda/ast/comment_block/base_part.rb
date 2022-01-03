require 'yoda/ast/comment_block/range_calculation'

module Yoda
  module AST
    class CommentBlock
      # @abstract
      class BasePart
        include RangeCalculation
      end
    end
  end
end
