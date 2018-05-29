module Yoda
  module Evaluation
    class CodeCompletion
      # WIP
      class VariableProvider < BaseProvider
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
