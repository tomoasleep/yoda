module Yoda
  module Evaluation
    class CommentCompletion
      # @type Store::Registry
      attr_reader :registry

      # @type ::Parser::AST::Node
      attr_reader :ast

      # @type Array<::Parser::Source::Comment>
      attr_reader :comments

      # @type Location
      attr_reader :location

      # @param registry [Store::Registry]
      # @param ast      [::Parser::AST::Node]
      # @param comments [Array<::Parser::Source::Comment>]
      # @param location [Location]
      def initialize(registry, ast, comments, location)
        @registry = registry
        @ast = ast
        @comments = comments
        @location = location
      end

      # @return [true, false]
      def valid?
        !!(current_comment_query.current_comment && current_comment_token_query.current_word)
      end

      # @return [Array<Model::Descriptions::Base>]
      def candidates
        return [] unless valid?
        case current_comment_token_query.current_state
        when :tag
          tag_candidates
        when :param
          param_candidates
        when :type
          const_candidates
        when :type_tag_type
          const_candidates
        else
          []
        end
      end

      # @return [Parsing::Range, nil]
      def substitution_range
        return nil unless valid?

        if %i(type type_tag_type).include?(current_comment_token_query.current_state)
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
        else
          current_comment_token_query.current_range.move(
            row: current_comment_query.begin_point_of_current_comment_block.row - 1,
            column: current_comment_query.begin_point_of_current_comment_block.column,
          )
        end
      end

      private

      def param_candidates
        []
      end

      # @return [Parsing::Query::CurrentCommentTokenQuery]
      def current_comment_token_query
        @current_comment_token_query ||= Parsing::Query::CurrentCommentTokenQuery.new(current_comment_query.current_comment_block_text, current_comment_query.location_in_current_comment_block)
      end

      # @return [Parsing::Query::CurrentCommentQuery]
      def current_comment_query
        @current_comment_query ||= Parsing::Query::CurrentCommentQuery.new(comments, location)
      end

      # @return [String]
      def index_word
         if %i(type type_tag_type).include?(current_comment_token_query.current_state) && (current_comment_token_query.at_sign?)
          ''
        else
          current_comment_token_query.current_word || ''
        end
      end

      # @return [CurrentCommentingNodeQuery]
      def current_commenting_node_query
        Parsing::Query::CurrentCommentingNodeQuery.new(ast, comments, location)
      end

      # @group methods for tag completion

      # @return [Array<String>]
      def tagnames
        @tagnames ||= YARD::Tags::Library.labels.map { |tag_symbol, label| "@#{tag_symbol}" }
      end

      # @return [Array<Model::Descriptions::WordDescription>]
      def tag_candidates
        tagnames.select { |tagname| tagname.start_with?(index_word) }.map { |obj| Model::Descriptions::WordDescription.new(obj) }
      end

      # @group methods for const completion

      # @return [NodeObjects::Namespace, nil]
      def namespace
        current_commenting_node_query.current_namespace
      end

      # @return [Array<Model::Descriptions::ValueDescription>]
      def const_candidates
        scoped_path = Model::ScopedPath.new(namespace.paths_from_root, index_word)
        Store::Query::FindConstant.new(registry).select_with_prefix(scoped_path).map { |obj| Model::Descriptions::ValueDescription.new(obj) }
      end
    end
  end
end
