module Yoda
  module Services
    class CommentCompletion
      class TypeProvider < BaseProvider
        # @return [true, false]
        def available?
          [:type, :type_tag_type].include?(current_comment_token_query.current_state)
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          description_candidates.map { |description| Model::CompletionItem.new(description: description, range: substitution_range) }
        end

        private

        # @return [Array<Model::Descriptions::Base>]
        def description_candidates
          return [] unless available?
          return [] unless namespace
          scoped_path = Model::ScopedPath.new(lexical_scope(namespace), index_word)
          Store::Query::FindConstant.new(registry).select_with_prefix(scoped_path).map { |obj| Model::Descriptions::ValueDescription.new(obj) }
        end

        # @return [Parsing::Range, nil]
        def substitution_range
          return nil unless available?
          # @todo Move this routine to Parsing module
          if current_comment_token_query.current_range
            range = current_comment_token_query.current_range.move(
              row: current_comment_query.begin_point_of_current_comment_block.row - 1,
              column: current_comment_query.begin_point_of_current_comment_block.column,
            )
            cut_point = current_comment_token_query.at_sign? ? 1 : (current_comment_token_query.current_word.rindex('::') || -2) + 2
            Parsing::Range.new(range.begin_location.move(row: 0, column: cut_point), range.end_location)
          else
            Parsing::Range.new(location, location)
          end
        end

        # @return [String]
        def index_word
          current_comment_token_query.at_sign? ? '' : current_comment_token_query.current_word
        end

        # @return [AST::Namespace, nil]
        def namespace
          current_commenting_node_query.current_namespace
        end

        # @param namespace [AST::Namespace]
        # @return [Array<Path>]
        def lexical_scope(namespace)
          evaluator.node_info(namespace).scope_nestings.reverse.map(&:path)
        end
      end
    end
  end
end
