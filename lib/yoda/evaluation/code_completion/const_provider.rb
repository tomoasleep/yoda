module Yoda
  module Evaluation
    class CodeCompletion
      class ConstProvider < BaseProvider
        # @return [true, false]
        def providable?
          false
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          []
        end
      end
    end
  end
end
