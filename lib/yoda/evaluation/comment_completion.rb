module Yoda
  module Evaluation
    class CommentCompletion
      attr_reader :registry, :ast, :comments, :location

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

      # @return [Array<Descriptions::Base>]
      def candidates
        return [] unless valid?
        case current_comment_token_query.current_state
        when :tag
          tag_candidates
        when :param
          param_candidates
        when :type
          const_candidates
        else
          []
        end
      end

      # @return [Range, nil]
      def substitution_range
        return nil unless valid?

        current_comment_token_query.current_range.move(
          row: current_comment_query.begin_point_of_current_comment_block.row - 1,
          column: current_comment_query.begin_point_of_current_comment_block.column,
        )
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

      # @return [String, nil]
      def index_word
        current_comment_token_query.current_word
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

      # @return [Array<Descriptions::WordDescription>]
      def tag_candidates
        tagnames.select { |tagname| tagname.start_with?(index_word) }.map { |obj| Descriptions::WordDescription.new(obj) }
      end

      # @group methods for const completion

      # @return [NodeObjects::Namespace, nil]
      def namespace
        current_commenting_node_query.current_namespace
      end

      # @return [Array<Descriptions::ValueDescription>]
      def const_candidates
        paths = namespace ? namespace.paths_from_root : ['']
        paths.map { |path| registry.search_objects_with_prefix(path, index_word) }.flatten.map { |obj| Descriptions::ValueDescription.new(obj) }
      end
    end
  end
end