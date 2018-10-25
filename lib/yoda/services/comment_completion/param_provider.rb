module Yoda
  module Services
    class CommentCompletion
      # @note WIP
      class ParamProvider < BaseProvider
        # @return [true, false]
        def available?
          current_comment_token_query.current_state == :param
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          []
        end
      end
    end
  end
end
