module Yoda
  module Services
    class CommentCompletion
      # @abstract
      class BaseProvider
        # @type Model::Environment
        attr_reader :environment

        # @type ::Parser::AST::Node
        attr_reader :ast

        # @type Array<::Parser::Source::Comment>
        attr_reader :comments

        # @type Location
        attr_reader :location

        # @param environment [Model::Environment]
        # @param ast      [::Parser::AST::Node]
        # @param comments [Array<::Parser::Source::Comment>]
        # @param location [Location]
        def initialize(environment, ast, comments, location)
          @environment = environment
          @ast = ast
          @comments = comments
          @location = location
        end

        # @abstract
        # @return [true, false]
        def available?
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<Model::CompletionItem>]
        def candidates
          fail NotImplementedError
        end

        private

        # @return [Evaluator]
        def evaluator
          @evaluator ||= Evaluator.new(ast: ast, environment: environment)
        end

        # @return [Parsing::Query::CurrentCommentTokenQuery]
        def current_comment_token_query
          @current_comment_token_query ||=
            Parsing::Query::CurrentCommentTokenQuery.new(
              current_comment_query.current_comment_block_text,
              current_comment_query.location_in_current_comment_block,
            )
        end

        # @return [Parsing::Query::CurrentCommentQuery]
        def current_comment_query
          @current_comment_query ||= Parsing::Query::CurrentCommentQuery.new(comments, location)
        end

        # @return [CurrentCommentingNodeQuery]
        def current_commenting_node_query
          Parsing::Query::CurrentCommentingNodeQuery.new(ast, comments, location)
        end
      end
    end
  end
end
