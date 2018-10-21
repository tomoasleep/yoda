module Yoda
  module Commands
    class CommentCompletion
      class TagProvider < BaseProvider
        # @return [true, false]
        def available?
          current_comment_token_query.current_state == :tag
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          description_candidates.map { |description| Model::CompletionItem.new(description: description, range: substitution_range) }
        end

        private

        # @return [Array<Model::Descriptions::WordDescription>]
        def description_candidates
          return [] unless available?
          tagnames.select { |tagname| tagname.start_with?(index_word) }.map { |obj| Model::Descriptions::WordDescription.new(obj) }
        end

        # @return [Parsing::Range, nil]
        def substitution_range
          return nil unless available?
          current_comment_query.absolute_range(current_comment_token_query.current_range)
        end

        # @return [String]
        def index_word
          current_comment_token_query.current_word
        end

        # @return [Array<String>]
        def tagnames
          @tagnames ||= YARD::Tags::Library.labels.map { |tag_symbol, label| "@#{tag_symbol}" }
        end
      end
    end
  end
end
